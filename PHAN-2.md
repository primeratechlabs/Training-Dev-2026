# Phần 2: Ghi chú công việc trong WorkBoard

**Thời gian:** 8 giờ

**Điểm tối đa:** 100

Trong đợt chạy thử WorkBoard, nhóm vận hành muốn ghi lại trao đổi gắn với từng công việc mà không làm đổi trạng thái. Họ cần xem lại toàn bộ lịch sử và thấy ghi chú mới trên trang chi tiết.

Dùng một bản sao source code Phần 1 để làm tiếp; bản đã nộp để chấm được giữ nguyên. Dùng lại cơ sở dữ liệu và quy ước response trong `PHAN-1.md`. Không cần tạo thêm bảng.

## 1. Ghi nhận và hiển thị ghi chú — 65 điểm

```http
POST /api/work-items/{id}/notes
```

Request:

```json
{ "note": "Đã thống nhất cách xử lý với nhóm giao diện" }
```

- `id` phải là số nguyên dương. ID sai định dạng hoặc nhỏ hơn 1 trả 400; công việc không tồn tại hoặc đã bị xóa mềm trả 404.
- `note` là bắt buộc. Bỏ khoảng trắng ở đầu và cuối trước khi lưu; nội dung sau khi bỏ khoảng trắng dài từ 1 đến 1.000 ký tự. Dữ liệu không hợp lệ trả 400 và chỉ rõ lỗi ở `note`.
- Có thể ghi chú cho mọi công việc chưa bị xóa, kể cả công việc đã Done hoặc Cancelled.
- Tạo một bản ghi trong `work_item_histories`. `fromStatus` và `toStatus` cùng bằng trạng thái hiện tại của công việc; `changedBy` là `api`. Không đổi trạng thái.
- Cập nhật `updated_at` của công việc. Thời điểm tạo bản ghi lịch sử và `updated_at` phải là cùng một thời điểm UTC.
- Bản ghi lịch sử và cập nhật của công việc phải cùng được lưu hoặc cùng bị hủy nếu có lỗi.
- Thành công trả 201, có header `Location: /api/work-items/{id}/history`. Trong `data` trả về bản ghi lịch sử vừa tạo, gồm `id`, `fromStatus`, `toStatus`, `note`, `changedBy` và `createdAt`.
- Sau khi ghi chú thành công, `GET /api/work-items/{id}` vẫn trả đầy đủ các phần đã quy định trong P1-R03. ID sai định dạng hoặc nhỏ hơn 1 trả 400; công việc không tồn tại hoặc đã bị xóa mềm trả 404. Trường `history` có thêm bản ghi vừa tạo.

## 2. Xem lịch sử — 25 điểm

```http
GET /api/work-items/{id}/history
```

- ID sai định dạng hoặc nhỏ hơn 1 trả 400. Công việc không tồn tại hoặc đã bị xóa mềm trả 404.
- Thành công trả 200. `data` là mảng các bản ghi gồm `id`, `fromStatus`, `toStatus`, `note`, `changedBy` và `createdAt`.
- Trả đủ bản ghi lịch sử hiện có, kể cả bản ghi có `note: null`. Sắp xếp theo `createdAt` tăng dần; nếu trùng thời điểm thì sắp xếp theo `id` tăng dần.
- Công việc chưa có bản ghi lịch sử trả 200 với `data: []`.

## 3. Phần mở rộng: lọc theo ngày — 10 điểm

Cho phép lọc các bản ghi lịch sử bằng hai tham số query tùy chọn:

```text
from=2026-09-01
to=2026-09-30
```

Ngày dùng đúng dạng `YYYY-MM-DD` theo UTC. `from` tính từ đầu ngày được chọn; `to` bao gồm hết ngày được chọn. Có thể gửi riêng từng tham số. Ngày sai định dạng trả 400 và chỉ rõ field lỗi; nếu `from` muộn hơn `to`, lỗi chỉ rõ cả hai field. Thực hiện lọc trong truy vấn database.

Các response thành công có body và response lỗi dùng cấu trúc chung trong `PHAN-1.md`.

## Gợi ý

- Xem cách các bảng `work_items` và `work_item_histories` liên hệ với nhau trong `database.sql`.
- Khi ghi chú, cần xác định trạng thái hiện tại của công việc và lưu các thay đổi liên quan cùng nhau.
- API chi tiết và API lịch sử cùng hiển thị dữ liệu từ `work_item_histories`; hãy giữ kết quả nhất quán giữa hai nơi.
- Với phần lọc ngày, xác định điều kiện và thứ tự sắp xếp trước khi lấy dữ liệu trả về.
- Bạn tự chọn cách chia file và cách xử lý để code dễ theo dõi.

## Bài cần nộp

- Toàn bộ source code sau Phần 2.
- File `README.md` hướng dẫn cấu hình database, chạy ứng dụng và gọi các API mới.
- `BAO-CAO-SAU-PHAN-1.md`, hoàn thành sau thời gian tự học và nộp trước khi bắt đầu phần code Phần 2.

Các quy định sử dụng công cụ và cách bàn giao trong `README.md` vẫn áp dụng.
