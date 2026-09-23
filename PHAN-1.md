# Phần 1: Xây dựng WorkBoard API

**Thời gian:** 8 giờ  
**Điểm tối đa:** 100

Sau khi đọc `README.md`, hãy tạo solution và xây dựng phiên bản đầu tiên của WorkBoard. Các route dưới đây thuộc cùng một API.

## 1. Quy ước chung

- Base path: `/api`.
- JSON dùng camelCase. Các giá trị enum trả bằng tên, không trả bằng số.
- Thời gian trả theo ISO-8601, có UTC `Z` hoặc offset.
- Response có body dùng `Content-Type: application/json`.
- Connection string đọc từ configuration hoặc environment variable.
- Không trả stack trace, câu SQL hoặc connection string cho client.

Response thành công không dùng một cấu trúc bọc chung. Body, mã HTTP và header được quy định theo từng API bên dưới; không tự thêm lớp bọc như `data`. Riêng API xóa thành công trả 204 và không có body.

Các response lỗi của những API trong đề dùng cùng cấu trúc dưới đây, trừ response 503 của health check. `status` phải trùng với mã HTTP. `traceId` là mã theo dõi request; `message` mô tả ngắn lỗi; `errors` là object rỗng nếu lỗi không gắn với field cụ thể. Nội dung cụ thể của `message` không cần khớp với câu trong ví dụ. Khi dữ liệu đầu vào sai, `errors` ghi lỗi theo tên field:

```json
{
  "traceId": "mã theo dõi request",
  "status": 400,
  "message": "Dữ liệu không hợp lệ",
  "errors": {
    "title": ["title phải dài từ 5 đến 200 ký tự"]
  }
}
```

Chạy `database.sql` một lần trên database trống trước khi làm bài. Dùng EF Core để làm việc với các bảng và cột đã có; không tạo một bộ bảng khác thay cho cấu trúc trong file SQL. Giữ nguyên tên bảng, tên cột và các giá trị trạng thái, mức ưu tiên đã có. Bạn có thể thêm index nếu cần.

Trong các route có `{id}`, ID phải là số nguyên dương. ID sai định dạng hoặc nhỏ hơn 1 trả 400; ID hợp lệ nhưng không tìm thấy bản ghi trả 404.

## 2. Các API cần làm

### P1-R01. Health check (5 điểm)

```http
GET /api/health
```

Response 200:

```json
{ "status": "ok", "dbConnected": true }
```

Route phải kiểm tra kết nối PostgreSQL. Khi không kết nối được, trả 503 với `{ "status": "unavailable", "dbConnected": false }`.

### P1-R02. Danh sách công việc (20 điểm)

```http
GET /api/work-items
```

Các query parameter có thể dùng:

```text
keyword
status=Todo,InProgress
priority=High
projectCode=WEB
assigneeId=2
overdue=true
page=1
pageSize=20
sort=-createdAt
```

Quy tắc:

- Không trả item có `is_deleted=true`.
- `keyword` tìm trong title, không phân biệt chữ hoa và chữ thường.
- `status` nhận một hoặc nhiều giá trị, cách nhau bằng dấu phẩy: `Todo`, `InProgress`, `Blocked`, `Done`, `Cancelled`.
- `priority` nhận một trong các giá trị `Low`, `Normal`, `High`, `Urgent`.
- Có thể có khoảng trắng quanh từng giá trị status. Giá trị rỗng hoặc không hợp lệ trả 400 và chỉ rõ field lỗi. Giá trị status lặp lại chỉ được tính một lần. Status và priority phải đúng chữ hoa/thường như các giá trị nêu trên.
- `priority` và `projectCode` được trim trước khi so khớp. `projectCode` so khớp chính xác với code trong database. Nếu `keyword` hoặc `projectCode` rỗng sau khi trim thì không áp dụng điều kiện tương ứng.
- `assigneeId` phải là số nguyên dương; giá trị khác trả 400 và chỉ rõ field lỗi.
- `overdue` mặc định là `false`; chỉ nhận `true` hoặc `false` viết thường. Giá trị khác trả 400. Khi là `false` hoặc không được gửi, không áp dụng điều kiện quá hạn.
- `page` mặc định là 1 và phải là số nguyên từ 1 trở lên.
- `pageSize` mặc định là 20 và phải là số nguyên từ 1 đến 50.
- Chỉ nhận một giá trị sort: `createdAt`, `dueAt` hoặc `priority`; thêm dấu `-` phía trước để sắp xếp giảm dần. Không có dấu `-` thì sắp xếp tăng dần. Giá trị khác trả 400 và chỉ rõ field lỗi.
- Thứ tự priority: Urgent > High > Normal > Low.
- Khi sort theo priority, chiều tăng dần là Low, Normal, High, Urgent; chiều giảm dần là thứ tự ngược lại.
- Khi sort theo `dueAt`, giá trị `null` luôn nằm cuối danh sách.
- `overdue=true` chỉ lấy item có `dueAt` trước thời điểm hiện tại theo UTC và status không phải Done/Cancelled. `dueAt` bằng hoặc sau thời điểm hiện tại không được tính là quá hạn.
- Mặc định sắp xếp theo `createdAt` giảm dần.
- Nếu nhiều item có cùng giá trị sắp xếp, dùng `id` tăng dần để giữ thứ tự ổn định.
- Filter, sort và paging phải chạy ở database.
- `total` là tổng số item sau khi áp dụng các filter, nhưng trước khi phân trang. Không tự loại item chỉ vì project hoặc developer đang inactive.

Ví dụ response 200 khi lọc `status=InProgress&priority=Urgent&projectCode=WEB` trên dữ liệu mẫu vừa tạo:

```json
{
  "page": 1,
  "pageSize": 20,
  "total": 1,
  "items": [{
    "id": 1,
    "code": "WI-2026-000001",
    "title": "Sửa lỗi đăng nhập",
    "status": "InProgress",
    "priority": "Urgent",
    "projectCode": "WEB",
    "projectName": "Cổng thông tin khách hàng",
    "assigneeId": 1,
    "assigneeName": "Nguyễn An",
    "dueAt": "2026-09-21T02:00:00Z",
    "createdAt": "2026-09-15T02:00:00Z",
    "updatedAt": "2026-09-16T02:00:00Z",
    "labels": ["backend", "bug", "urgent"]
  }]
}
```

Kết quả ví dụ dùng các trường trong phần tử của `items`; khi assignee chưa được giao, `assigneeId` và `assigneeName` là `null`. Nhãn được sắp xếp theo tên tăng dần. Các mốc thời gian trong ví dụ tương ứng với trường hợp chạy file SQL lúc 02:00 UTC ngày 23/09/2026. File SQL dùng `now()`, nên thời gian thực tế sẽ khác. Query không hợp lệ trả 400 và chỉ rõ field lỗi. Không có kết quả vẫn trả 200 với `total: 0` và `items: []`.

### P1-R03. Chi tiết công việc (10 điểm)

```http
GET /api/work-items/{id}
```

Response 200 có năm phần ở cấp ngoài:

- `item` gồm thông tin chính của work item: `id`, `code`, `title`, `description`, `status`, `priority`, `dueAt`, `createdAt`, `updatedAt`, `completedAt`.
- `project` gồm `code` và `name`.
- `assignee` gồm `id`, `code`, `fullName`, hoặc là `null` nếu chưa giao việc.
- `labels` là mảng tên nhãn, sắp xếp theo tên tăng dần.
- `history` là mảng lịch sử, sắp xếp tăng dần theo `createdAt`; nếu trùng thời điểm thì sắp xếp theo `id` tăng dần. Mỗi bản ghi có `fromStatus`, `toStatus`, `note`, `changedBy` và `createdAt`.

Item không tồn tại hoặc đã xóa mềm trả 404. Response cần có đủ dữ liệu quan hệ, kể cả khi item chưa có assignee hoặc history.

### P1-R04. Tạo công việc (20 điểm)

```http
POST /api/work-items
```

Request mẫu:

```json
{
  "title": "Hoàn thiện màn hình đăng nhập",
  "description": "Bổ sung kiểm tra dữ liệu đăng nhập",
  "projectCode": "WEB",
  "assigneeId": 2,
  "priority": "High",
  "dueAt": "2030-10-15T10:00:00Z",
  "labels": ["frontend", "urgent", "FRONTEND"]
}
```

Validation:

- `title`: bắt buộc, trim trước khi kiểm tra, dài từ 5 đến 200 ký tự;
- `description`: có thể bỏ trống hoặc là `null`, tối đa 2.000 ký tự;
- `projectCode`: bắt buộc sau khi trim khoảng trắng ở hai đầu; phải khớp chính xác code của một project active;
- `assigneeId`: có thể bỏ trống hoặc là `null`; nếu có giá trị, developer phải active;
- `priority`: nhận đúng một trong các giá trị Low, Normal, High hoặc Urgent;
- `dueAt`: có thể bỏ trống hoặc là `null`; nếu có thì phải sau thời điểm nhận request theo UTC;
- `labels`: có thể bỏ trống hoặc là `null`. Với mỗi tên, trim khoảng trắng ở hai đầu, bỏ tên rỗng, chuyển thành chữ thường rồi loại trùng. Mỗi tên còn lại dài tối đa 50 ký tự và toàn bộ danh sách có tối đa 5 tên sau khi chuẩn hóa.

Khi tạo thành công:

- status ban đầu là Todo;
- sau khi PostgreSQL cấp `id`, code có dạng `WI-{năm UTC tại thời điểm tạo}-{id}`; phần `id` có ít nhất 6 chữ số, thêm số 0 ở đầu nếu cần và không cắt bớt khi dài hơn 6 chữ số;
- tạo work item, liên kết các label và history `null → Todo` trong cùng một transaction;
- nếu tên label sau chuẩn hóa đã có trong database thì dùng lại label đó; chỉ tạo label chưa tồn tại;
- history khởi tạo có `fromStatus: null`, `toStatus: Todo`, `note: null`, `changedBy: api` và cùng thời điểm với `createdAt`;
- đặt `createdAt` và `updatedAt` bằng cùng một thời điểm UTC khi tạo. Thời điểm này cũng là `createdAt` của history khởi tạo;
- trả 201;
- header `Location` là `/api/work-items/{id}`;
- body là một object có cùng các field với một phần tử trong `items` của API danh sách; không bọc trong `page`, `pageSize`, `total` hoặc `items`.

Giá trị `title` sau khi trim là giá trị được lưu. Input sai trả 400. Project không tồn tại hoặc không active, developer không tồn tại hoặc không active trả 422. Nếu một bước ghi dữ liệu lỗi, transaction phải rollback.

### P1-R05. Giao việc (10 điểm)

```http
PATCH /api/work-items/{id}/assignee
```

```json
{ "assigneeId": 3, "note": "Chuyển cho backend" }
```

- Request phải có field `assigneeId`; giá trị `null` nghĩa là bỏ phân công. Nếu field bị thiếu hoặc có giá trị không phải số nguyên/null, trả 400. `note` có thể bỏ trống hoặc là `null`, tối đa 1.000 ký tự.
- Developer phải active.
- Item đã xóa mềm trả 404, như item không tồn tại. Không thay đổi assignee của item Done hoặc Cancelled; các trường hợp này trả 422.
- Nếu `assigneeId` có giá trị, developer không tồn tại hoặc không active thì trả 422.
- Mỗi request hợp lệ đều cập nhật `updated_at` và ghi một bản ghi vào `work_item_histories` trong cùng một transaction, kể cả khi assignee mới trùng với assignee hiện tại. Khi chỉ thay người phụ trách, `from_status` và `to_status` cùng bằng trạng thái hiện tại. `changedBy` của history do API này ghi là `api`.
- Nếu `note` dài hơn 1.000 ký tự thì trả 400.
- Nếu `note` bị bỏ trống hoặc là `null`, lưu `note: null` trong history.
- Thành công trả 200 với một object có cùng các field với một phần tử trong `items` của API danh sách; không bọc trong `page`, `pageSize`, `total` hoặc `items`. Không tìm thấy trả 404; vi phạm nghiệp vụ trả 422.

### P1-R06. Xóa mềm (10 điểm)

```http
DELETE /api/work-items/{id}
```

- Chỉ item Todo hoặc Cancelled được xóa. Trạng thái khác trả 409.
- Không xóa bản ghi khỏi database. Cập nhật `is_deleted`, `deleted_at` và `updated_at` bằng cùng một thời điểm UTC.
- Thành công trả 204, không có body.
- Gọi lại cùng ID trả 404.
- Item đã xóa không xuất hiện trong danh sách, chi tiết hoặc báo cáo.

### P1-R07. Báo cáo theo project (10 điểm)

```http
GET /api/reports/project-summary?minItems=0
```

Một dòng trong response trên dữ liệu mẫu vừa tạo:

```json
[{
  "projectCode": "WEB",
  "projectName": "Cổng thông tin khách hàng",
  "totalItems": 4,
  "openItems": 3,
  "overdueItems": 2,
  "doneItems": 1,
  "averageCompletionHours": 384.0
}]
```

- `from`, `to`, `minItems` là các query parameter tùy chọn. Ngày dùng dạng `YYYY-MM-DD`; `minItems` mặc định là 0 và phải không âm.
- Báo cáo chỉ gồm project active. Project active chưa có item vẫn xuất hiện khi `minItems=0`; project inactive không xuất hiện, kể cả khi có item.
- Lọc item theo `createdAt` và ngày UTC. `from` tính từ đầu ngày được chọn; `to` bao gồm hết ngày được chọn. Khi có cả hai, `from` phải không muộn hơn `to`.
- Không tính item đã xóa.
- `totalItems` là số item không bị xóa sau khi áp dụng khoảng ngày. Chỉ trả project có `totalItems >= minItems`.
- `openItems` đếm các item chưa Done/Cancelled. `overdueItems` chỉ đếm item quá hạn, chưa Done/Cancelled.
- `averageCompletionHours` là số giờ trung bình từ `createdAt` đến `completedAt` của các item Done trong cùng khoảng ngày; làm tròn đến một chữ số thập phân và bằng `null` nếu chưa có item hoàn thành.
- `minItems` phải là số nguyên không âm. Ngày sai định dạng, `from` muộn hơn `to` hoặc `minItems` không hợp lệ trả 400 và chỉ rõ field lỗi.
- Các dòng báo cáo sắp xếp theo `projectCode` tăng dần.
- Aggregate bằng truy vấn database; không tải toàn bộ bảng về để cộng bằng vòng lặp.

### P1-R08. Response lỗi (5 điểm)

- Các lỗi đầu vào, không tìm thấy và vi phạm nghiệp vụ trả đúng mã HTTP đã nêu ở từng API.
- Response lỗi có cùng cấu trúc ở các route. Lỗi đầu vào cần chỉ rõ field chưa hợp lệ.
- Lỗi không dự kiến trả 500. Không gửi stack trace, câu SQL hoặc thông tin kết nối database cho client.

### P1-Q01. Chất lượng code và bàn giao (10 điểm)

- 2 điểm: project build và chạy được theo hướng dẫn đã nộp.
- 2 điểm: thao tác đọc, ghi PostgreSQL qua EF Core dùng async.
- 1 điểm: tên biến và phương thức giúp người đọc hiểu chúng đang làm việc gì.
- 1 điểm: phần xử lý được dùng chung ở nhiều nơi không bị chép lại nguyên khối.
- 1 điểm: request và response chỉ có các trường cần thiết, không trả thừa dữ liệu từ database.
- 1 điểm: không đưa secret, thư mục `bin` hoặc `obj` vào bài nộp.
- 2 điểm: README trong source code nêu cách cấu hình chuỗi kết nối, chạy ứng dụng và địa chỉ các API.

## 3. Lưu ý khi triển khai

- Dữ liệu mẫu chỉ giúp bạn bắt đầu. API phải xử lý đúng khi database có thêm project, developer, work item và label khác.
- Việc lọc, sắp xếp, phân trang và tính báo cáo cần dựa trên dữ liệu trong PostgreSQL; tránh tải toàn bộ dữ liệu về rồi mới xử lý trong ứng dụng.
- Những thao tác cùng tạo ra một kết quả nghiệp vụ cần nằm trong cùng transaction.
- Nếu thiếu thời gian, hãy hoàn thiện từng API từ request đến dữ liệu trả về trước khi chuyển sang API tiếp theo.

Một API hoàn chỉnh và chạy đúng được tính điểm cao hơn nhiều API mới chỉ tạo route.
