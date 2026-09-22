# PHẦN 1 — XÂY DỰNG WORKBOARD API TỪ ĐẦU

**Thời gian:** 8 giờ liên tục  
**Công nghệ bắt buộc:** ASP.NET Core .NET 10, EF Core 10, PostgreSQL  
**Được phép:** Google, tài liệu chính thức, Stack Overflow  
**Không được phép trong thời gian thi:** dùng AI, trao đổi hoặc nhận code từ người khác

## 1. Nhiệm vụ của bạn

Trước khi bắt đầu, hãy đọc `business-context.md`. Bạn sẽ tham gia xây dựng WorkBoard, một API nội bộ được công ty Sao Bắc dùng thay cho bảng tính theo dõi công việc.

Mục tiêu của Phần 1 là tạo ra một phiên bản đủ dùng cho Team Lead và dashboard trong phạm vi một nhóm. Sau 8 giờ, API cần đáp ứng được các nhu cầu sau:

1. biết hệ thống và database có đang hoạt động hay không;
2. tìm, lọc và sắp xếp công việc;
3. xem đầy đủ một công việc cùng nhãn và lịch sử;
4. tạo và giao việc mà vẫn bảo đảm tính toàn vẹn của dữ liệu;
5. xóa mềm để dữ liệu vẫn được lưu trong database;
6. xem báo cáo ngắn theo project;
7. trả lỗi theo một cấu trúc nhất quán để frontend xử lý.

Bạn sẽ tự tạo toàn bộ repository và quyết định cách chia project, layer, class, interface, DI, validation và test. Đề bài không bắt buộc một cấu trúc thư mục hay pattern cụ thể. Bộ chấm sẽ chạy ứng dụng từ bên ngoài, gọi HTTP API và kiểm tra trực tiếp dữ liệu trong PostgreSQL.

## 2. Phần nào được tự quyết định?

Đề bài chỉ quy định những yếu tố ảnh hưởng đến khả năng tích hợp, gồm route, input, output, validation, status code và side effect trong database. Với những phần còn lại, bạn được tự quyết định để thể hiện cách tư duy và tổ chức kỹ thuật.

Bạn có thể tự chọn:

- cách chia solution và project;
- cách đặt tên class, interface và method;
- thư viện validation hoặc mapping;
- cách tổ chức business logic;
- cách viết unit test hoặc integration test;
- dùng controller, minimal API hay kết hợp cả hai, miễn là không làm thay đổi contract.

## 3. Quy ước chung của API

- Base path là `/api`.
- JSON dùng camelCase; enum trả bằng tên, không trả bằng số.
- Thời gian dùng ISO-8601, có offset hoặc UTC `Z`.
- Mọi response có body phải dùng `Content-Type: application/json`.
- Không trả stack trace, câu SQL hoặc connection string cho client.

Mọi lỗi phải có cùng cấu trúc:

```json
{
  "traceId": "guid hoặc correlation id",
  "status": 400,
  "message": "Dữ liệu không hợp lệ",
  "errors": {
    "title": ["title phải dài 5–200 ký tự"]
  }
}
```

Field nào không có lỗi thì không xuất hiện trong `errors`.

## 4. Database contract

Chạy file `database.sql` để tạo schema và dữ liệu mẫu. Không được đổi tên các bảng, cột hoặc enum value đã có. Bạn có thể thêm index và migration, miễn là các thay đổi này không phá vỡ contract. Connection string phải được đọc từ configuration hoặc environment variable, không hard-code trong source code.

## 5. Các chức năng cần xây dựng

### P1-R01 — Kiểm tra hệ thống: `GET /api/health` — 4 điểm

Hệ thống giám sát sẽ gọi route này để kiểm tra cả hai điều kiện: API vẫn đang chạy và kết nối tới PostgreSQL vẫn hoạt động.

Response thành công:

```json
{ "status": "ok", "dbConnected": true }
```

- Phải kiểm tra kết nối PostgreSQL thật, không được trả một giá trị `true` cố định.
- Khi không kết nối được với database, API có thể trả 503 cùng `dbConnected:false`.

**Hoàn thành khi:** route trả 200 với đúng cấu trúc khi PostgreSQL hoạt động, đồng thời không báo trạng thái khỏe khi database không thể truy cập.

### P1-R02 — Màn hình danh sách: `GET /api/work-items` — 18 điểm

Mỗi sáng, Team Lead mở dashboard để tìm công việc theo project, người phụ trách, trạng thái và mức ưu tiên. Vì danh sách có thể lớn, toàn bộ thao tác lọc, sắp xếp và phân trang phải được thực hiện trong database.

Các query parameter:

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

Quy tắc xử lý:

- Không trả về work item có `is_deleted=true`.
- `keyword` được dùng để tìm trong title, không phân biệt chữ hoa và chữ thường.
- `status` có thể nhận nhiều giá trị phân tách bằng dấu phẩy; tất cả giá trị đều phải là enum hợp lệ.
- `page` mặc định là 1 và phải lớn hơn hoặc bằng 1.
- `pageSize` mặc định là 20, chỉ nhận từ 1 đến 50.
- Chỉ cho phép sắp xếp theo `createdAt`, `dueAt` hoặc `priority`; dấu `-` biểu thị thứ tự giảm dần.
- Thứ tự priority theo nghiệp vụ là Urgent > High > Normal > Low.
- `overdue=true` chỉ lấy những công việc có `dueAt` trước thời điểm hiện tại và chưa ở trạng thái Done hoặc Cancelled.
- Việc filter, sort và paging phải được thực hiện trong database.

Response 200:

```json
{
  "page": 1,
  "pageSize": 20,
  "total": 42,
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
    "dueAt": "2026-09-20T02:00:00Z",
    "createdAt": "2026-09-14T02:00:00Z",
    "updatedAt": null,
    "labels": ["backend", "bug"]
  }]
}
```

Nếu enum, sort hoặc paging không hợp lệ, API phải trả 400 và chỉ rõ field bị lỗi. Trường hợp không có kết quả vẫn trả 200 với `total: 0` và `items: []`.

### P1-R03 — Xem một công việc: `GET /api/work-items/{id}` — 8 điểm

Khi mở một dòng trên dashboard, Team Lead cần xem được thông tin công việc, project, người được giao, labels và toàn bộ history.

- `history` phải được sắp xếp tăng dần theo `createdAt`.
- Nếu work item không tồn tại hoặc đã bị xóa mềm, API trả 404.
- Số lượng query không được tăng theo số label hoặc số bản ghi history của item.

### P1-R04 — Tạo công việc: `POST /api/work-items` — 20 điểm

Team Lead dùng route này để ghi nhận một lỗi hoặc yêu cầu mới.

Request mẫu:

```json
{
  "title": "Hoàn thiện màn hình đăng nhập",
  "description": "Bổ sung validation phía client",
  "projectCode": "WEB",
  "assigneeId": 2,
  "priority": "High",
  "dueAt": "2026-10-15T10:00:00Z",
  "labels": ["frontend", "urgent", "FRONTEND"]
}
```

Validation:

- trim `title` trước khi kiểm tra; độ dài sau khi trim phải từ 5 đến 200 ký tự;
- `description` được dài tối đa 2.000 ký tự;
- `projectCode` là bắt buộc và phải trỏ tới một project active;
- `assigneeId` không bắt buộc; nếu được cung cấp thì phải trỏ tới một developer active;
- `priority` bắt buộc và chỉ nhận Low/Normal/High/Urgent;
- `dueAt`, nếu có, phải ở tương lai;
- với `labels`: trim từng giá trị, bỏ chuỗi rỗng, loại bỏ giá trị trùng nhau mà không phân biệt hoa thường; sau khi xử lý, danh sách được có tối đa 5 labels.

Khi tạo thành công:

- trạng thái ban đầu là Todo;
- code có dạng `WI-{năm}-{id gồm 6 chữ số}`;
- work item, label mới, các liên kết và bản ghi history đầu tiên `null → Todo` phải được ghi trong cùng một transaction;
- trả 201;
- header `Location` là `/api/work-items/{id}`;
- body dùng cùng shape với một item trong danh sách.

Input không hợp lệ phải trả 400; project hoặc developer không hợp lệ phải trả 422. Nếu lỗi xảy ra ở bất kỳ bước ghi dữ liệu nào, toàn bộ transaction phải được rollback.

### P1-R05 — Giao hoặc bỏ giao việc: `PATCH /api/work-items/{id}/assignee` — 10 điểm

Trong lúc phân công, Team Lead có thể chuyển việc cho một developer khác hoặc đưa item về trạng thái chưa có người nhận.

```json
{ "assigneeId": 3, "note": "Chuyển cho backend" }
```

- `assigneeId:null` nghĩa là bỏ phân công.
- Nếu `assigneeId` có giá trị, ID đó phải trỏ tới một developer active.
- Không được thay đổi assignee của item đang ở trạng thái Done, Cancelled hoặc đã bị xóa.
- Việc cập nhật `updated_at` và ghi history phải nằm trong cùng một transaction.
- Thành công trả 200; không tìm thấy item trả 404; vi phạm quy tắc nghiệp vụ trả 422.

### P1-R06 — Xóa mềm công việc: `DELETE /api/work-items/{id}` — 8 điểm

Sao Bắc cần giữ lại dữ liệu để đối soát, vì vậy route này không được xóa vật lý bản ghi khỏi database.

- Chỉ item ở trạng thái Todo hoặc Cancelled mới được xóa; các trạng thái khác trả 409.
- Xóa mềm bằng `is_deleted`, `deleted_at` và `updated_at`.
- Thành công trả 204, không có body.
- Nếu gọi lại lần thứ hai, API trả 404.
- Item đã xóa không được xuất hiện trong list, detail hoặc report.

### P1-R07 — Báo cáo họp sáng: `GET /api/reports/project-summary` — 12 điểm

Trước cuộc họp hằng ngày, Team Lead cần xem nhanh số liệu tổng hợp theo project thay vì phải đếm từng dòng trong bảng tính.

Các query parameter không bắt buộc gồm `from`, `to` và `minItems`.

```json
[{
  "projectCode": "WEB",
  "projectName": "Cổng thông tin khách hàng",
  "totalItems": 4,
  "openItems": 2,
  "overdueItems": 2,
  "doneItems": 1,
  "averageCompletionHours": 384.0
}]
```

- Khi `minItems=0`, những project active chưa có item vẫn phải xuất hiện.
- `averageCompletionHours` là null nếu project chưa có item nào hoàn thành.
- Không tính item đã xóa.
- `from` và `to` lọc theo `createdAt`; mốc `to` bao gồm toàn bộ ngày được truyền vào.
- Phép aggregate phải được thực hiện bằng database/LINQ query; không được tải toàn bộ bảng về rồi dùng `foreach` để cộng dồn.

### P1-R08 — Theo dõi request và xử lý lỗi — 8 điểm

Khi frontend báo lỗi, Team Lead cần một ID để tìm đúng request trong log. Vì vậy:

- mọi response phải có header `X-Correlation-Id`;
- nếu request gửi kèm một GUID hợp lệ thì phải giữ nguyên GUID đó;
- nếu header bị thiếu hoặc không phải GUID hợp lệ thì sinh một GUID mới;
- lỗi ngoài dự kiến phải trả response 500 an toàn và được ghi log với cùng correlation ID;
- không lặp lại logic `try/catch` để đổi status code trong từng controller.

### P1-Q01 — Test và bàn giao — 12 điểm

Bài làm phải có ít nhất 6 automated tests do chính bạn viết, trong đó bao gồm validation, happy path và ít nhất một trường hợp kiểm tra rollback hoặc soft delete.

Bạn cũng cần:

- viết README hoặc `SUBMISSION.md` theo mẫu đã phát;
- cung cấp hướng dẫn để Team Lead có thể build, cấu hình database và chạy ứng dụng từ một repository sạch;
- commit theo từng lát cắt có ý nghĩa;
- không commit secret, `bin` hoặc `obj`;
- ghi trung thực route nào đã xong, route nào còn lỗi.

## 6. Nếu không đủ thời gian

Bạn không cần cố làm tất cả cùng lúc. Để sớm có một sản phẩm chạy được, có thể triển khai theo thứ tự sau:

**Health → list → detail → create → delete → assign → report → mở rộng test.**

Bạn có thể chọn thứ tự khác nếu có chiến lược rõ ràng. Một route hoàn chỉnh, có validation và test, sẽ có giá trị hơn nhiều route mới chỉ có controller nhưng chưa chạy đúng.

## 7. Bộ chấm sẽ quan sát gì?

Bộ chấm không yêu cầu một tên class hay pattern cụ thể. Team Lead sẽ kiểm tra:

- route, status code, header và JSON contract;
- validation ở các giá trị biên;
- trạng thái của PostgreSQL sau các thao tác create, rollback, assign và soft delete;
- N+1 và nơi thực hiện filter/sort/paging;
- khả năng build/test từ repository sạch;
- hành vi của API dưới tải đồng thời;
- khả năng giải thích các quyết định trong code đã nộp.
