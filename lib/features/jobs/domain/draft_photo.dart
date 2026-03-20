class DraftPhoto {
  final int? id;
  final String path;
  final bool isNew;
  bool markedForDeletion;

  DraftPhoto({
    this.id,
    required this.path,
    required this.isNew,
    this.markedForDeletion = false,
  });
}
