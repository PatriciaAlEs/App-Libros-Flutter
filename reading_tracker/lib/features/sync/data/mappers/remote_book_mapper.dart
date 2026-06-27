import '../../domain/entities/remote_book.dart';
import '../models/remote_book_dto.dart';

extension RemoteBookDtoMapper on RemoteBookDto {
  RemoteBook toDomain() {
    return RemoteBook(
      id: id,
      userId: userId,
      localBookId: localBookId,
      title: title,
      author: author,
      isbn: isbn,
      coverUrl: coverUrl,
      totalPages: totalPages,
      currentPage: currentPage,
      status: status,
      rating: rating,
      startedAt: startedAt,
      finishedAt: finishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension RemoteBookMapper on RemoteBook {
  RemoteBookDto toDto() {
    return RemoteBookDto(
      id: id,
      userId: userId,
      localBookId: localBookId,
      title: title,
      author: author,
      isbn: isbn,
      coverUrl: coverUrl,
      totalPages: totalPages,
      currentPage: currentPage,
      status: status,
      rating: rating,
      startedAt: startedAt,
      finishedAt: finishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}
