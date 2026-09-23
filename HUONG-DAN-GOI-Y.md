# Gợi ý khi làm bài WorkBoard

Tài liệu này giúp bạn chọn điểm bắt đầu và giữ bài làm đi đúng hướng. Đây không phải đáp án mẫu. Các route, dữ liệu trả về và quy tắc trong `PHAN-1.md` vẫn là căn cứ chính; bạn có thể tự chọn cách tổ chức và triển khai phù hợp.

## Trước khi viết code

Hãy đọc một lượt các route trong đề để hình dung WorkBoard cần làm gì. Sau đó mở `database.sql`, xem các bảng, cột và mối liên hệ giữa chúng. Đây là cấu trúc database mà API cần làm việc cùng; không cần tạo thêm một bộ bảng khác. Tên trong PostgreSQL thường có dạng `work_items`, `assignee_id`, còn tên class và property trong C# thường được viết khác đi. Hãy kiểm tra cách EF Core ghép hai phía với nhau.

Dữ liệu mẫu có những tình huống đáng chú ý như công việc chưa được giao, project đã đóng, developer không còn active, công việc đã xóa và project chưa có công việc. Nắm được các trường hợp này sẽ giúp bạn tránh chỉ làm API chạy đúng với một bản ghi quen thuộc.

Bạn có thể ghi nhanh mỗi route theo bốn ý: nhận dữ liệu gì, cần tìm hoặc thay đổi dữ liệu nào, khi nào được xem là thành công, và trường hợp nào cần trả lỗi. Bảng ghi chú ngắn này sẽ hữu ích khi bạn bắt đầu code và khi kiểm tra lại.

## Dựng ứng dụng và kiểm tra kết nối

Hãy tạo một ASP.NET Core Web API trên .NET 10, thêm các gói EF Core cần cho PostgreSQL rồi cấu hình chuỗi kết nối trong phần cấu hình của ứng dụng. Trước khi làm nhiều route, hãy chạy ứng dụng và xác nhận API kết nối được tới database. Nếu chưa kết nối được, kiểm tra lần lượt database đã chạy chưa, tên database và thông tin đăng nhập có đúng không, ứng dụng có đọc đúng chuỗi kết nối không.

Bạn không cần dựng cấu trúc dự án cầu kỳ. Một project Web API vẫn có thể chứa đầy đủ bài làm. Hãy đặt tên rõ ràng và sắp xếp các phần theo cách bạn dễ tìm lại khi cần sửa.

## Đi từ một route chạy được đến các route còn lại

Với mỗi route, hãy lần theo một đường đi hoàn chỉnh: nhận request, kiểm tra dữ liệu đầu vào, đọc hoặc ghi dữ liệu, rồi trả response cùng mã HTTP phù hợp. Khi route đầu tiên chạy được, bạn sẽ có một điểm tựa để mở rộng dần thay vì dựng nhiều route nhưng chưa route nào đi hết được đường này.

Nếu cần chọn thứ tự làm, có thể bắt đầu từ route đọc dữ liệu để làm quen với bảng và quan hệ; tiếp theo xử lý các thao tác tạo hoặc cập nhật; sau đó làm xóa mềm và báo cáo. Đây chỉ là một cách sắp xếp. Hãy cân nhắc điểm số, thời gian còn lại và phần bạn đang nắm chắc để chọn thứ tự phù hợp.

## Khi làm việc với dữ liệu

EF Core giúp bạn đọc và ghi dữ liệu bằng C#. Với route danh sách, hãy đưa điều kiện lọc, cách sắp xếp và giới hạn trang vào truy vấn gửi tới PostgreSQL; tránh lấy toàn bộ bảng về rồi mới xử lý trong ứng dụng. Với báo cáo, hãy xác định rõ mỗi con số được tính từ những bản ghi nào trước khi viết phần tổng hợp.

Một số thao tác tạo hoặc cập nhật cần ghi nhiều dữ liệu có liên quan. Hãy đọc kỹ đề để nhận ra thao tác nào phải được xem là một việc thống nhất: nếu một bước không thành công thì không nên để lại dữ liệu dở dang. EF Core có hỗ trợ transaction cho trường hợp này. Với code của work item, PostgreSQL cấp `id`; bạn cần có `id` trước khi tạo code cuối cùng. Hãy xử lý các bước này trong cùng transaction để nếu có lỗi thì không để lại bản ghi dở dang.

Khi xử lý nhãn, hãy phân biệt nhãn đã có trong database với nhãn mới. Tên nhãn được chuẩn hóa trước khi tìm; nếu đã có thì dùng lại, tránh tạo bản ghi trùng.

Với response thành công có body, các trường `traceId`, `status`, `message`, `data` luôn theo cùng một cấu trúc; phần `data` thay đổi theo từng API. Hãy nhìn vào mô tả của route để biết `data` cần có những trường nào. Dữ liệu liên quan như project, người phụ trách, nhãn hoặc lịch sử có thể không tồn tại ở mọi công việc; cách truy vấn và tạo response cần tính đến điều đó.

## Khi kết quả chưa như mong đợi

Hãy nhìn cả mã HTTP, nội dung JSON và dữ liệu trong PostgreSQL để khoanh vùng vấn đề. Nếu một công việc không xuất hiện như dự kiến, chẳng hạn, hãy xem lại điều kiện lọc, trạng thái xóa mềm và các dữ liệu liên quan như project, người phụ trách hoặc lịch sử. Nếu dữ liệu ghi xuống chưa đúng, lần theo các bước xử lý của request để tìm bước đầu tiên có kết quả khác mong đợi.

Dữ liệu mẫu có nhiều trạng thái khác nhau, nhưng API vẫn cần xử lý được khi không có kết quả hoặc một số dữ liệu liên quan không tồn tại. Nghĩ trước về những tình huống này sẽ giúp bạn tránh phụ thuộc vào một bản ghi duy nhất.

## Khi gặp vướng mắc

Hãy thu nhỏ vấn đề trước khi tìm cách sửa: route nào đang lỗi, request cụ thể là gì, ứng dụng trả về gì, và bạn mong đợi kết quả nào. Sau đó tra cứu tài liệu chính thức hoặc tìm đúng thông báo lỗi. Thử từng thay đổi nhỏ và kiểm tra lại, thay vì sửa nhiều phần cùng lúc.

Trong 8 giờ, ưu tiên hoàn thiện từng phần từ đầu đến cuối. Nếu một yêu cầu đang làm bạn mắc lại quá lâu, ghi chú chỗ vướng, chuyển sang phần khác có thể tiến triển, rồi quay lại khi có thêm manh mối. Một route chạy đúng với các trường hợp quan trọng giúp bạn có cơ sở tốt hơn để tiếp tục hoàn thiện bài.
