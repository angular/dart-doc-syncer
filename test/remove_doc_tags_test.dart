import "package:test/test.dart";

import "package:dart_doc_syncer/src/remove_doc_tags.dart";

void main() {
  group("removeDocTags", () {
    test("removes #docregion, #enddocregion, #docplaster tags (dart)", () {
      final code = '''
        // #docplaster
        // #docregion
        final dart = 'awesome';
        // #enddocregion
      ''';

      final cleanedCode = '''
        final dart = 'awesome';
      ''';

      expect(removeDocTags(code), equals(cleanedCode));
    });

    test("leaves non-comments alone (dart)", () {
      var code = '''
        final tag = '#enddocregion';
      ''';

      expect(removeDocTags(code), equals(code));
    });

    test("leaves comments without doc-tags alone (dart)", () {
      var code = '''
        // The sum will be 4.
        final sum = 2 + 2;
      ''';

      expect(removeDocTags(code), equals(code));
    });

    test("removes #docregion, #enddocregion, #docplaster tags (html)", () {
      final code = '''
        <!-- #docplaster -->
        <!-- #docregion greeting -->
        <div class='greeting'>
          <span>Hello {{name}}!</span>
        </div>
        <!-- #enddocregion greeting -->
      ''';

      final cleanedCode = '''
        <div class='greeting'>
          <span>Hello {{name}}!</span>
        </div>
      ''';

      expect(removeDocTags(code), equals(cleanedCode));
    });

    test("leaves non-comments alone (html)", () {
      var code = '''
        Example of a doc tag: <tag>#docplaster</tag>;
      ''';

      expect(removeDocTags(code), equals(code));
    });

    test("leaves comments without doc-tags alone (html)", () {
      var code = '''
        <!-- The sum will be 4 -->
        Sum: {{2 + 2}}
      ''';

      expect(removeDocTags(code), equals(code));
    });
  });
}
