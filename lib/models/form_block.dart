import 'layout_item.dart';

class FormBlock {
  final String id;
  final String title;
  final String description;
  final LayoutItem layout;

  FormBlock({
    required this.id,
    required this.title,
    required this.layout,
    this.description = "",
  });
}


