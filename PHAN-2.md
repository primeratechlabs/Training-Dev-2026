# Phần 2: Ghi chú và lịch sử công việc trong WorkBoard

**Thời gian:** 8 giờ | **Điểm tối đa:** 100

Trong đợt chạy thử WorkBoard, nhóm vận hành cần ghi chú vào từng công việc mà không làm đổi trạng thái. Khi mở trang chi tiết, họ muốn xem các ghi chú cùng lịch sử thay đổi trước đó.

Hãy tiếp tục phát triển source code WorkBoard trong thư mục bài làm; bản gốc được giữ riêng để chấm. Cấu trúc bảng và dữ liệu mẫu có trong `database.sql`.

## Quy ước response

Mọi API trả về JSON. Tên trường dùng camelCase; trạng thái và mức ưu tiên trả về bằng tên. Thời gian dùng định dạng ISO 8601, kèm `Z` nếu ở UTC hoặc offset múi giờ. `traceId` là mã theo dõi request.

Body của response thành công có cấu trúc sau. `status` phải trùng với mã HTTP, còn `data` chứa kết quả của API.

```json
{
  "traceId": "mã theo dõi request",
  "status": 201,
  "message": "Thành công",
  "data": {}
}
```

Body của response lỗi có cấu trúc dưới đây. Nếu lỗi không gắn với trường cụ thể, để `errors` là object rỗng. Nếu dữ liệu đầu vào không hợp lệ, dùng tên trường làm key trong `errors` và ghi nội dung lỗi tương ứng. `status` phải trùng với mã HTTP; `message` nêu ngắn gọn nguyên nhân lỗi.

```json
{
  "traceId": "mã theo dõi request",
  "status": 400,
  "message": "Dữ liệu không hợp lệ",
  "errors": {
    "note": ["note không được để trống"]
  }
}
```

## 1. Ghi và hiển thị ghi chú — 65 điểm

```http
POST /api/work-items/{id}/notes
```

Request:

```json
{ "note": "Đã thống nhất cách xử lý với nhóm giao diện" }
```

- `id` phải là số nguyên dương. Nếu ID sai định dạng hoặc nhỏ hơn 1, trả 400. Nếu công việc không tồn tại hoặc đã bị xóa mềm, trả 404.
- `note` phải là chuỗi và không được để trống. Bỏ khoảng trắng ở đầu và cuối trước khi lưu; nội dung sau khi bỏ khoảng trắng phải dài từ 1 đến 1.000 ký tự. Nếu không hợp lệ, trả 400 và nêu lỗi ở `note`.
- Có thể ghi chú cho mọi công việc chưa bị xóa mềm, kể cả công việc có trạng thái `Done` hoặc `Cancelled`.
- Tạo một bản ghi trong `work_item_histories`. Trong bản ghi, `fromStatus` và `toStatus` đều bằng trạng thái hiện tại của công việc, còn `changedBy` là `api`. Ghi chú không làm đổi trạng thái công việc.
- Cập nhật `updated_at` của công việc. Giá trị này phải bằng `created_at` của bản ghi lịch sử; cả hai thời điểm đều theo UTC.
- Lưu bản ghi lịch sử và cập nhật công việc cùng nhau. Nếu có lỗi, không để lại riêng một trong hai thay đổi.
- Khi ghi chú thành công, trả 201 cùng header `Location: /api/work-items/{id}/history`. Trong `data`, trả về bản ghi vừa tạo với các trường `id`, `fromStatus`, `toStatus`, `note`, `changedBy` và `createdAt`.

Khi gọi `GET /api/work-items/{id}`, response thành công trả 200. Trong `data` có `item`, `project`, `assignee`, `labels` và `history`. Ghi chú vừa tạo cũng phải xuất hiện trong `history`.

- `item` gồm `id`, `code`, `title`, `description`, `status`, `priority`, `dueAt`, `createdAt`, `updatedAt` và `completedAt`. `description`, `dueAt` và `completedAt` có thể là `null`.
- `project` có `code` và `name`.
- `assignee` có `id`, `code` và `fullName`; nếu chưa có người phụ trách thì trả `null`.
- `labels` là mảng tên nhãn, sắp xếp theo tên tăng dần.
- `history` gồm toàn bộ bản ghi lịch sử của công việc. Mỗi bản ghi có `id`, `fromStatus`, `toStatus`, `note`, `changedBy` và `createdAt`. Sắp xếp theo `createdAt` tăng dần; nếu hai bản ghi cùng thời điểm thì sắp xếp theo `id` tăng dần. Trường không có giá trị thì trả về `null`; nếu chưa có bản ghi, trả mảng rỗng.

Với route chi tiết, ID sai định dạng hoặc nhỏ hơn 1 thì trả 400. Nếu công việc không tồn tại hoặc đã bị xóa mềm, trả 404.

## 2. Xem lịch sử — 25 điểm

```http
GET /api/work-items/{id}/history
```

- ID sai định dạng hoặc nhỏ hơn 1 thì trả 400. Nếu công việc không tồn tại hoặc đã bị xóa mềm, trả 404.
- Request thành công trả 200. `data` là mảng bản ghi; mỗi bản ghi có `id`, `fromStatus`, `toStatus`, `note`, `changedBy` và `createdAt`. Trường không có giá trị thì trả về `null`.
- Trả đủ bản ghi lịch sử của công việc và sắp xếp theo `createdAt` tăng dần. Nếu hai bản ghi cùng thời điểm, sắp xếp theo `id` tăng dần.
- Nếu công việc chưa có bản ghi lịch sử, trả 200 với `data: []`.

## 3. Phần mở rộng: lọc lịch sử theo ngày — 10 điểm

API xem lịch sử nhận thêm hai query parameter tùy chọn:

```text
from=2026-09-01
to=2026-09-30
```

Lọc bản ghi theo `createdAt`. Ngày phải theo dạng `YYYY-MM-DD` và được hiểu theo UTC. Mốc `from` tính từ đầu ngày được chọn; mốc `to` bao gồm hết ngày đó. Có thể gửi riêng từng tham số. Ngày sai định dạng trả 400 và ghi lỗi theo tên tham số trong `errors`. Nếu `from` muộn hơn `to`, ghi lỗi cho cả hai tham số trong `errors`. Thực hiện lọc trong truy vấn database.

## Gợi ý

- Trong `database.sql`, bạn có thể xem mối liên hệ giữa `work_items` và `work_item_histories`.
- Trang chi tiết và API lịch sử cùng đọc dữ liệu từ `work_item_histories`, nên kết quả ở hai nơi cần nhất quán.
- Với bộ lọc ngày, hãy xác định khoảng thời gian cần lấy và thứ tự sắp xếp.
- Bạn có thể tự chọn cách chia file và tổ chức phần xử lý.

## Bài cần nộp

- Toàn bộ source code sau khi hoàn thành.
- File `README.md` hướng dẫn cấu hình database, chạy ứng dụng và gọi các API mới.
- File `BAO-CAO-SAU-PHAN-1.md`, hoàn thành sau thời gian tự học và nộp trước khi bắt đầu làm phần code.

Các quy định về công cụ và cách nộp bài trong `README.md` vẫn áp dụng.
