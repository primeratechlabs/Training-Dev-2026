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

Các response lỗi dùng cùng cấu trúc dưới đây, trừ response 503 của health check. Trường `errors` ghi lỗi theo tên field khi có lỗi đầu vào:

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

Chạy `database.sql` trên database trống trước khi làm bài. Giữ nguyên tên bảng, tên cột và các giá trị trạng thái, mức ưu tiên đã có. Bạn có thể thêm index nếu cần.

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
- `status` nhận một hoặc nhiều giá trị, cách nhau bằng dấu phẩy.
- `priority` nhận một trong bốn mức ưu tiên đã có trong database.
- `page` mặc định là 1 và phải lớn hơn hoặc bằng 1.
- `pageSize` mặc định là 20, chỉ nhận từ 1 đến 50.
- Chỉ cho phép sort theo `createdAt`, `dueAt`, `priority`. Dấu `-` nghĩa là giảm dần.
- Thứ tự priority: Urgent > High > Normal > Low.
- `overdue=true` chỉ lấy item có `dueAt` trước thời điểm hiện tại và status không phải Done/Cancelled.
- Mặc định sắp xếp theo `createdAt` giảm dần.
- Filter, sort và paging phải chạy ở database.

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

Các mốc thời gian trong ví dụ tương ứng với trường hợp chạy file SQL lúc 02:00 UTC ngày 23/09/2026. File SQL dùng `now()`, nên thời gian thực tế sẽ khác. Query không hợp lệ trả 400 và chỉ rõ field lỗi. Không có kết quả vẫn trả 200 với `total: 0` và `items: []`.

### P1-R03. Chi tiết công việc (10 điểm)

```http
GET /api/work-items/{id}
```

Response 200 có năm phần ở cấp ngoài:

- `item` gồm thông tin chính của work item: `id`, `code`, `title`, `description`, `status`, `priority`, `dueAt`, `createdAt`, `updatedAt`, `completedAt`.
- `project` gồm `code` và `name`.
- `assignee` gồm `id`, `code`, `fullName`, hoặc là `null` nếu chưa giao việc.
- `labels` là mảng tên nhãn.
- `history` là mảng lịch sử, sắp xếp tăng dần theo `createdAt`. Mỗi bản ghi có `fromStatus`, `toStatus`, `note`, `changedBy` và `createdAt`.

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
- `description`: có thể bỏ trống, tối đa 2.000 ký tự;
- `projectCode`: bắt buộc, project phải active;
- `assigneeId`: không bắt buộc; nếu có, developer phải active;
- `priority`: Low, Normal, High hoặc Urgent;
- `dueAt`: có thể bỏ trống, nếu có thì phải ở tương lai;
- `labels`: có thể bỏ trống. Nếu có, hãy trim từng tên, bỏ chuỗi rỗng, chuyển về chữ thường và loại trùng. Tối đa 5 nhãn sau khi chuẩn hóa, mỗi tên dài không quá 50 ký tự.

Khi tạo thành công:

- status ban đầu là Todo;
- code có dạng `WI-{năm UTC}-{id gồm ít nhất 6 chữ số}`;
- tạo work item, label mới, liên kết label và history `null → Todo` trong cùng một transaction;
- đặt `createdAt` và `updatedAt` theo thời điểm tạo;
- trả 201;
- header `Location` là `/api/work-items/{id}`;
- body dùng cùng cấu trúc với item ở API danh sách.

Input sai trả 400. Project hoặc developer không hợp lệ trả 422. Nếu một bước ghi dữ liệu lỗi, transaction phải rollback.

### P1-R05. Giao việc (10 điểm)

```http
PATCH /api/work-items/{id}/assignee
```

```json
{ "assigneeId": 3, "note": "Chuyển cho backend" }
```

- `assigneeId: null` nghĩa là bỏ phân công. `note` có thể bỏ trống, tối đa 1.000 ký tự.
- Developer phải active.
- Không thay đổi assignee của item Done, Cancelled hoặc đã xóa.
- Cập nhật `updated_at` và ghi một bản ghi vào `work_item_histories` trong cùng một transaction. Khi chỉ thay người phụ trách, `from_status` và `to_status` cùng bằng trạng thái hiện tại.
- Thành công trả 200 với body như một item ở API danh sách; không tìm thấy trả 404; vi phạm nghiệp vụ trả 422.

### P1-R06. Xóa mềm (10 điểm)

```http
DELETE /api/work-items/{id}
```

- Chỉ item Todo hoặc Cancelled được xóa. Trạng thái khác trả 409.
- Không xóa bản ghi khỏi database. Cập nhật `is_deleted`, `deleted_at` và `updated_at`.
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
- Lọc `from` và `to` theo `createdAt`; `to` bao gồm hết ngày đã chọn.
- Không tính item đã xóa.
- Project active chưa có item vẫn xuất hiện khi `minItems=0`.
- `openItems` đếm các item chưa Done/Cancelled. `overdueItems` chỉ đếm item quá hạn, chưa Done/Cancelled.
- `averageCompletionHours` là số giờ trung bình từ `createdAt` đến `completedAt` của các item Done; bằng `null` nếu chưa có item hoàn thành.
- Khoảng ngày hoặc `minItems` không hợp lệ trả 400.
- Aggregate bằng truy vấn database; không tải toàn bộ bảng về để cộng bằng vòng lặp.

### P1-R08. Response lỗi (5 điểm)

- Các lỗi đầu vào, không tìm thấy và vi phạm nghiệp vụ trả đúng mã HTTP đã nêu ở từng API.
- Response lỗi có cùng cấu trúc ở các route. Lỗi đầu vào cần chỉ rõ field chưa hợp lệ.
- Lỗi không dự kiến trả 500. Không gửi stack trace, câu SQL hoặc thông tin kết nối database cho client.

### P1-Q01. Chất lượng code và bàn giao (10 điểm)

- Project build và chạy được từ hướng dẫn đã nộp.
- Code dễ đọc, tên biến và phương thức thể hiện đúng việc chúng làm.
- Request và response chỉ chứa những trường cần thiết; không trả thừa dữ liệu từ database.
- Các đoạn xử lý dùng lại ở nhiều nơi không bị chép lại nguyên khối.
- EF Core dùng async khi đọc hoặc ghi database.
- Không commit secret, `bin` hoặc `obj`.
- Có hướng dẫn đủ để leader cấu hình database và chạy ứng dụng.

## 3. Lưu ý khi triển khai

- Dữ liệu mẫu chỉ giúp bạn bắt đầu. API phải xử lý đúng khi database có thêm project, developer, work item và label khác.
- Việc lọc, sắp xếp, phân trang và tính báo cáo cần dựa trên dữ liệu trong PostgreSQL; tránh tải toàn bộ dữ liệu về rồi mới xử lý trong ứng dụng.
- Những thao tác cùng tạo ra một kết quả nghiệp vụ cần nằm trong cùng transaction.
- Nếu thiếu thời gian, hãy hoàn thiện từng API từ request đến dữ liệu trả về trước khi chuyển sang API tiếp theo.

Một API hoàn chỉnh và chạy đúng được tính điểm cao hơn nhiều API mới chỉ tạo route.
