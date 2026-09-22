# Bối cảnh chung — hệ thống WorkBoard

> **Lưu ý:** Công ty Sao Bắc và tình huống dưới đây là bối cảnh giả định dùng riêng cho bài thi.

## Công ty đang gặp vấn đề gì?

Công ty phần mềm Sao Bắc đang theo dõi công việc của các nhóm phát triển bằng một bảng tính dùng chung. Mỗi dòng là một việc cần làm, chẳng hạn sửa lỗi đăng nhập, viết test cho tính năng thanh toán hoặc xử lý cảnh báo máy chủ.

Cách làm này đủ dùng khi số việc còn ít. Tuy nhiên, khi nhiều dự án cùng hoạt động, nhóm bắt đầu gặp những vấn đề quen thuộc:

- mỗi người lọc và sắp xếp bảng theo một cách khác nhau;
- một công việc có thể bị xóa nhầm mà không còn dấu vết;
- nhãn bị nhập trùng vì khác chữ hoa, chữ thường hoặc có khoảng trắng;
- leader phải tự đếm việc trễ hạn và làm báo cáo bằng tay;
- hai người sửa cùng một dòng có thể ghi đè kết quả của nhau;
- không có cách kiểm soát client nào chỉ được xem và client nào được thay đổi dữ liệu.

Sao Bắc quyết định xây dựng **WorkBoard**, một API nội bộ để thay cho bảng tính. Giao diện web sẽ được làm ở dự án khác; trong bài thi này, bạn chỉ xây dựng backend API.

## Dữ liệu nghiệp vụ

Một `work item` là đơn vị công việc chính của WorkBoard:

- thuộc đúng một `project`;
- có thể chưa giao cho ai hoặc được giao cho một `developer`;
- có một `status`: `Todo`, `InProgress`, `Blocked`, `Done` hoặc `Cancelled`;
- có một `priority`: `Low`, `Normal`, `High` hoặc `Urgent`;
- có thể gắn nhiều `label`;
- có `history` để biết thay đổi nào đã diễn ra.

File `database.sql` đã có schema và dữ liệu mẫu cho các project `WEB`, `OPS`, `MOB`, `LAB` cùng một số work item. Đây là database contract của hệ thống, không phải gợi ý về cách chia code.

## Người dùng hệ thống

- **Team Lead** tạo việc, giao việc, hủy việc và xem báo cáo.
- **Developer** xem việc được giao và cập nhật tiến độ.
- **Viewer** chỉ xem dashboard hoặc báo cáo.
- **Hệ thống giám sát** gọi health check để biết API và PostgreSQL còn hoạt động hay không.

## Hai giai đoạn phát triển

### Phần 1 — API dùng được cho một nhóm

Bạn dựng hệ thống từ đầu. Sau 8 giờ, WorkBoard cần hỗ trợ các thao tác cơ bản: xem danh sách, xem chi tiết, tạo việc, giao việc, xóa mềm và xem báo cáo theo project. API cũng phải trả lỗi nhất quán để nhóm frontend có thể tích hợp.

### Phần 2 — mở rộng sau khi chạy thử

Sau 3–4 ngày, bạn tiếp tục từ chính bài đã nộp ở Phần 1. WorkBoard lúc này có nhiều client và nhiều người cùng thao tác. Hệ thống cần thêm API key, phân quyền, hàng đợi việc quá hạn, state machine, optimistic concurrency và các báo cáo phục vụ quản lý.

## Phạm vi bài thi

Bạn không cần làm giao diện, đăng nhập người dùng, gửi email, triển khai cloud hoặc viết tài liệu phân tích dài. Hãy tập trung vào HTTP contract, nghiệp vụ, tính toàn vẹn dữ liệu, khả năng kiểm thử và cách tổ chức một codebase mà người khác có thể tiếp tục phát triển.
