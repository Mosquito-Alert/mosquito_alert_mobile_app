import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:html/dom_parsing.dart';
import 'package:flutter_html/flutter_html.dart' as html;

String getHtmlText(String htmlString) {
  final document = parse(htmlString);
  final node = document.body ?? document.documentElement;
  if (node == null) {
    return '';
  }
  return _getNodeText(node);
}

String prepareHtmlBody(String htmlString) {
  // NOTE: removing 'font-feature-settings: normal;' to avoid issues with
  // certain fonts not rendering correctly on some devices.
  // See: https://github.com/Sub6Resources/flutter_html/issues/1362
  // See: https://github.com/Sub6Resources/flutter_html/issues/1380
  htmlString = htmlString.replaceAll('font-feature-settings: normal;', '');
  return _removeImgStyleAttributes(htmlString);
}

// Function to remove style attributes from all elements
String _removeImgStyleAttributes(String htmlString) {
  // Parse the HTML content
  final document = html.HtmlParser.parseHTML(htmlString);

  // Could be removed if ever this PR is merged: https://github.com/Sub6Resources/flutter_html/pull/1359
  // Remove style attributes from all elements
  document.querySelectorAll('img').forEach((element) {
    element.attributes.remove('style');
    element.attributes.remove('height');
    element.attributes.remove('width');
  });

  // Return the modified HTML as a string
  return document.outerHtml;
}

String _getNodeText(Node node, {String separator = ' '}) =>
    (_JoinTextVisitor(separator: separator)..visit(node)).toString();

class _JoinTextVisitor extends TreeVisitor {
  final StringBuffer _buffer = StringBuffer();
  final String separator;
  bool _needsSeparator = false;

  _JoinTextVisitor({this.separator = ' '});

  @override
  String toString() => _buffer.toString();

  @override
  void visitText(Text node) {
    final trimmed = node.data.trim();
    if (trimmed.isNotEmpty) {
      // This does not need separator.
      if (_needsSeparator) _buffer.write(separator);
      _buffer.write(trimmed);
      _needsSeparator = true;
    }
  }
}
