import 'dart:convert';
import 'package:path/path.dart' as p;

import '../example2uri.dart';
import 'options.dart';

/// Holds metadata about the example application that is used to generate a
/// README file.
class SyncData {
  final String name; // e.g., 'architecture'
  final String path; // e.g., 'ng/doc/architecture'
  final String title; // e.g. 'Architecture Overview'
  final String docPart; // e.g. 'guide' (from 'guide/architecture')
  final String docHref;
  final String repoHref;
  final String liveExampleHref;
  final List<String> links;

  String get id => path;

  SyncData(
      {String name: '',
      this.title: '',
      String docPart: '',
      String docHref: '',
      String liveExampleHref: '',
      this.links: const [],
      String repoHref: '',
      String path})
      : this.name = _name(name, path),
        this.path = path,
        this.docPart = docPart,
        this.docHref = docHref.isEmpty
            ? p.join(options.webdevURL, docPart, _name(name, path))
            : docHref.startsWith('http')
                ? docHref
                : p.join(options.webdevURL, docPart, docHref),
        this.liveExampleHref = liveExampleHref == null
            ? p.join(options.webdevURL, docExampleDirRoot, _name(name, path))
            : liveExampleHref.startsWith('http') || liveExampleHref.isEmpty
                ? liveExampleHref
                : p.join(options.webdevURL, liveExampleHref),
        this.repoHref = repoHref.isEmpty
            ? '//github.com/dart-lang/site-webdev/tree/${options.branch}/' + path
            : repoHref;

  static String _name(String name, String path) =>
      name.isEmpty ? getExampleName(path) : name;

  factory SyncData.fromJson(String json, {String path}) {
    final data = jsonDecode(json);
    return new SyncData(
        name: data['name'] ?? '',
        title: data['title'] ?? '',
        docPart: data['docPart'] ?? '',
        docHref: data['docHref'] ?? '',
        repoHref: data['repoHref'] ?? '',
        liveExampleHref: data['liveExampleHref'],
        links: data['links'] ?? [],
        path: path);
  }
}
