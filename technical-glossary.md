# Thuật ngữ dùng trong đề

Tài liệu này giải thích cách đề đang dùng các thuật ngữ. Phần giải thích giúp bạn đọc đúng yêu cầu, không quy định một cách cài đặt duy nhất.

| Thuật ngữ | Nghĩa trong bài |
|---|---|
| **HTTP contract** | Thỏa thuận giữa API và client về route, method, input, output, header và status code. Code bên trong có thể thay đổi nhưng contract đã công bố phải giữ nguyên. |
| **Validation** | Kiểm tra input có đúng kiểu, phạm vi và quy tắc đã nêu hay không. Input sai thường trả 400; vi phạm luật nghiệp vụ có thể trả 422. |
| **Business rule** | Luật xuất phát từ nghiệp vụ WorkBoard, ví dụ item Done không được đổi assignee hoặc item phải có assignee trước khi chuyển sang InProgress. |
| **Transaction** | Một nhóm thao tác ghi dữ liệu được xem như một đơn vị. Hoặc tất cả cùng thành công, hoặc database trở về trạng thái trước khi bắt đầu. |
| **Rollback** | Hủy các thay đổi của transaction khi một bước thất bại, tránh để lại dữ liệu chỉ được ghi một phần. |
| **Soft delete** | Đánh dấu dữ liệu đã xóa nhưng vẫn giữ bản ghi trong database. Trong đề này dùng `is_deleted` và `deleted_at`. |
| **Side effect** | Thay đổi có thể quan sát ngoài response, chẳng hạn thêm history, đổi assignee hoặc tạo liên kết label trong database. |
| **Idempotent** | Gọi cùng một request nhiều lần vẫn dẫn đến cùng trạng thái cuối, không tạo thêm dữ liệu trùng chỉ vì request bị lặp. |
| **State machine** | Tập trạng thái và các hướng chuyển hợp lệ giữa chúng. Không phải cặp trạng thái nào cũng được chuyển trực tiếp. |
| **Optimistic concurrency** | Cách phát hiện dữ liệu đã bị người khác cập nhật kể từ lúc client đọc nó. Thay vì khóa lâu, API so sánh version hoặc timestamp trước khi ghi. |
| **Lost update** | Một cập nhật mới bị ghi đè bởi client đang giữ dữ liệu cũ mà hệ thống không phát hiện. |
| **N+1 query** | Sau query đầu tiên lấy danh sách, ứng dụng lại chạy thêm một query cho từng dòng. Số query vì thế tăng theo số item và dễ làm API chậm. |
| **Projection** | Chọn trực tiếp các field cần trả về thay vì tải toàn bộ entity và quan hệ không cần thiết. |
| **DI lifetime** | Thời gian sống của dependency trong Dependency Injection, thường gặp là transient, scoped và singleton. `DbContext` thường là scoped và không được giữ trực tiếp trong singleton. |
| **Correlation ID** | Mã đi cùng một request để đối chiếu response với log khi điều tra lỗi. |
| **Black-box test** | Test gọi API từ bên ngoài và quan sát response hoặc database; test không phụ thuộc tên class hay cấu trúc source code. |
| **Stress/load test** | Kiểm tra hành vi của hệ thống khi có nhiều request đồng thời. Kết quả phụ thuộc cả code và máy chạy test. |
