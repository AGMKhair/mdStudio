import '../entities/folder.dart';

abstract class FolderRepository {
  Future<List<Folder>> getFolders();
  Future<Folder?> getFolderById(int id);
  Future<Folder> saveFolder(Folder folder);
  Future<void> updateFolder(Folder folder);
  Future<void> deleteFolder(int id);
}
