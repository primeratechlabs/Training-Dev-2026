# Phần 2: Ghi chú công việc trong WorkBoard

**Thời gian:** 8 giờ

**Điểm tối đa:** 100

Trong đợt chạy thử WorkBoard, nhóm vận hành muốn ghi lại trao đổi gắn với từng công việc mà không làm đổi trạng thái. Họ cần xem lại toàn bộ lịch sử và thấy ghi chú mới trên trang chi tiết.

Tiếp tục phát triển source code WorkBoard trong thư mục bài làm; bản source code ban đầu được giữ riêng để chấm. Cấu trúc bảng và dữ liệu mẫu nằm trong `database.sql`.

## Quy ước response

Các API trả về JSON, tên trường theo camelCase. Trạng thái và mức ưu tiên trả về bằng tên. Thời gian dùng định dạng ISO-8601, có UTC `Z` hoặc offset. `traceId` là mã theo dõi request.

Response thành công có body theo cấu trúc sau. `status` phải trùng với mã HTTP; `data` chứa kết quả của API.

```json
{
  "traceId": "mã theo dõi request",
  "status": 201,
  "message": "Thành công",
  "data": {}
}
```

Response lỗi dùng cấu trúc dưới đây. `errors` là object rỗng nếu lỗi không gắn với trường cụ thể; nếu dữ liệu đầu vào sai, ghi lỗi theo tên trường. `status` phải trùng với mã HTTP. `message` nêu ngắn gọn nguyên nhân lỗi.

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

## 1. Ghi nhận và hiển thị ghi chú — 65 điểm

```http
POST /api/work-items/{id}/notes
```

Request:

```json
{ "note": "Đã thống nhất cách xử lý với nhóm giao diện" }
```

- `id` phải là số nguyên dương. ID sai định dạng hoặc nhỏ hơn 1 trả 400; công việc không tồn tại hoặc đã bị xóa mềm trả 404.
- `note` là chuỗi bắt buộc. Bỏ khoảng trắng ở đầu và cuối trước khi lưu; nội dung sau khi bỏ khoảng trắng dài từ 1 đến 1.000 ký tự. Dữ liệu không hợp lệ trả 400 và chỉ rõ lỗi ở `note`.
- Có thể ghi chú cho mọi công việc chưa bị xóa, kể cả công việc đã Done hoặc Cancelled.
- Tạo một bản ghi trong `work_item_histories`. `fromStatus` và `toStatus` cùng bằng trạng thái hiện tại của công việc; `changedBy` là `api`. Không đổi trạng thái.
- Cập nhật `updated_at` của công việc. Thời điểm tạo bản ghi lịch sử và `updated_at` phải là cùng một thời điểm UTC.
- Bản ghi lịch sử và cập nhật của công việc phải cùng được lưu hoặc cùng bị hủy nếu có lỗi.
- Thành công trả 201, có header `Location: /api/work-items/{id}/history`. Trong `data` trả về bản ghi lịch sử vừa tạo, gồm `id`, `fromStatus`, `toStatus`, `note`, `changedBy` và `createdAt`.

Trong response thành công của `GET /api/work-items/{id}`, `data` gồm `item`, `project`, `assignee`, `labels` và `history`. Sau khi ghi chú thành công, mục `history` có bản ghi ghi chú vừa tạo.

- `item` gồm `id`, `code`, `title`, `description`, `status`, `priority`, `dueAt`, `createdAt`, `updatedAt` và `completedAt`. `description`, `dueAt` và `completedAt` có thể là `null`.
- `project`: `code` và `name`.
- `assignee`: `id`, `code` và `fullName`; trả `null` nếu chưa có người phụ trách.
- `labels`: mảng tên nhãn, sắp xếp tăng dần theo tên.
- `history`: mảng gồm toàn bộ bản ghi lịch sử của công việc, mỗi bản ghi có `id`, `fromStatus`, `toStatus`, `note`, `changedBy` và `createdAt`. Sắp xếp tăng dần theo `createdAt`; nếu trùng thời điểm thì sắp xếp theo `id` tăng dần. Trường không có giá trị được trả về là `null`; chưa có bản ghi thì trả mảng rỗng.

Request hợp lệ cho công việc đang tồn tại trả 200. ID của route chi tiết sai định dạng hoặc nhỏ hơn 1 trả 400; công việc không tồn tại hoặc đã bị xóa mềm trả 404.

## 2. Xem lịch sử — 25 điểm

```http
GET /api/work-items/{id}/history
```

- ID sai định dạng hoặc nhỏ hơn 1 trả 400. Công việc không tồn tại hoặc đã bị xóa mềm trả 404.
- Thành công trả 200. `data` là mảng các bản ghi gồm `id`, `fromStatus`, `toStatus`, `note`, `changedBy` và `createdAt`. Trường nào không có giá trị thì trả `null`.
- Trả đủ bản ghi lịch sử hiện có. Sắp xếp theo `createdAt` tăng dần; nếu trùng thời điểm thì sắp xếp theo `id` tăng dần.
- Công việc chưa có bản ghi lịch sử trả 200 với `data: []`.

## 3. Phần mở rộng: lọc theo ngày — 10 điểm

Cho phép lọc các bản ghi lịch sử bằng hai tham số query tùy chọn:

```text
from=2026-09-01
to=2026-09-30
```

Lọc theo `createdAt`, với ngày theo dạng `YYYY-MM-DD` và được hiểu theo UTC. `from` tính từ đầu ngày được chọn; `to` bao gồm hết ngày được chọn. Có thể gửi riêng từng tham số. Ngày sai định dạng trả 400 và chỉ rõ tham số bị lỗi; nếu `from` muộn hơn `to`, lỗi phải nêu cả hai tham số. Thực hiện lọc trong truy vấn database.

## Gợi ý

- Xem cách các bảng `work_items` và `work_item_histories` liên hệ với nhau trong `database.sql`.
- Khi ghi chú, cần xác định trạng thái hiện tại của công việc và lưu các thay đổi liên quan cùng nhau.
- Trang chi tiết và API lịch sử cùng hiển thị dữ liệu từ `work_item_histories`; hãy giữ kết quả nhất quán giữa hai nơi.
- Với phần lọc ngày, xác định điều kiện và thứ tự sắp xếp trước khi lấy dữ liệu trả về.
- Bạn tự chọn cách chia file và cách xử lý để code dễ theo dõi.

## Bài cần nộp

- Toàn bộ source code sau Phần 2.
- File `README.md` hướng dẫn cấu hình database, chạy ứng dụng và gọi các API mới.
- `BAO-CAO-SAU-PHAN-1.md`, hoàn thành sau thời gian tự học và nộp trước khi bắt đầu phần code Phần 2.

Các quy định sử dụng công cụ và cách bàn giao đã nêu trong README vẫn áp dụng.
