# Bài đánh giá thực tập sinh backend .NET

## Bối cảnh

Công ty phần mềm Sao Bắc đang theo dõi công việc bằng một bảng tính dùng chung. Cách làm này bắt đầu bất tiện khi có nhiều dự án: khó lọc công việc, nhãn dễ bị nhập trùng, công việc đã xóa không còn dấu vết và báo cáo phải tổng hợp bằng tay.

Sao Bắc muốn có một API nội bộ tên là WorkBoard để xử lý các việc trên. Bạn phụ trách xây dựng API này bằng ASP.NET Core.

Mỗi công việc (`work item`) thuộc một dự án (`project`), có trạng thái, mức ưu tiên, người phụ trách và nhãn. Những thay đổi cần lưu lịch sử được nêu ở từng API. Dữ liệu mẫu có cả công việc nhập từ bảng tính nên một số bản ghi chưa có lịch sử. Cấu trúc bảng và dữ liệu mẫu nằm trong file SQL đi kèm.

## Phạm vi bài làm

Bạn tự tạo solution và xây dựng WorkBoard từ đầu. Mỗi buổi làm bài kéo dài 8 giờ. Leader sẽ phát đề của buổi đó khi bắt đầu.

Công nghệ bắt buộc: **ASP.NET Core .NET 10, EF Core 10 và PostgreSQL**.

Trong giờ làm bài, bạn được dùng Google, tài liệu chính thức và Stack Overflow. Không được dùng AI, trao đổi hoặc nhận code từ người khác.

## Cách tổ chức bài làm

Hãy ưu tiên làm cho các route trả đúng kết quả và lưu đúng dữ liệu. Sau đó, sắp xếp code để người khác dễ đọc:

- Controller nhận request và trả response. Chỉ đưa ra những trường API cần.
- Đặt tên biến và phương thức theo việc chúng làm. Nếu một đoạn xử lý được dùng ở nhiều nơi, tách nó ra để tránh chép lại.
- Dùng EF Core để đọc và ghi PostgreSQL. Dùng async cho thao tác với database.
- Đọc connection string từ cấu hình. Không đưa thông tin nhạy cảm thật vào source code.

Bạn có thể làm bài trong một Web API project. Tự chọn cách sắp xếp code phù hợp với những phần đã làm được.

## Bài cần nộp

- Toàn bộ source code.
- Một file `README.md` do bạn viết, hướng dẫn cách cấu hình database, chạy ứng dụng và địa chỉ API.
- `BAO-CAO-SAU-PHAN-1.md`, nộp sau ba ngày kể từ buổi làm Phần 1. Báo cáo trình bày những gì đã học, vấn đề đã gặp, kinh nghiệm rút ra và phần tự đánh giá.

Leader chấm qua kết quả gọi API, dữ liệu trong PostgreSQL và source code. Bài làm cần chạy đúng cả khi dữ liệu khác với dữ liệu mẫu.
