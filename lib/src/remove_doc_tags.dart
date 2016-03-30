/// Returns [code] with filtered out doc tag comment lines.
String removeDocTags(String code) =>
    code.split('\n').where(_isNotDocTagComment).join('\n');

final _docTags = ['#docregion', '#enddocregion', '#docplaster'];
final _commentPrefixes = ['//', '<!--', '#'];

/// Returns true if [line] is a not a comment line with a doc tag.
bool _isNotDocTagComment(String line) => !_isDocTagComment(line);

/// Returns true if [line] is a comment line with a doc tag.
bool _isDocTagComment(String line) =>
    _isComment(line) && _docTags.any((String tag) => line.contains(tag));

/// Returns true if [line] starts with any of the prefixes indicating the start
/// of a doc tag comment.
bool _isComment(String line) =>
    _commentPrefixes.any((String prefix) => line.trimLeft().startsWith(prefix));
