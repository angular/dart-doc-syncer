import 'dart:convert';

import 'package:dart_doc_syncer/example2uri.dart';
import 'package:path/path.dart' as p;

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
      : this.name = name.isEmpty ? getExampleName(path) : name,
        this.path = path,
        this.docPart = docPart,
        this.docHref = docHref.isEmpty
            ? p.join(dartDocHostUri, docPart, getExampleName(path))
            : docHref.startsWith('http')
                ? docHref
                : p.join(dartDocHostUri, docPart, docHref),
        this.liveExampleHref = liveExampleHref == null
            ? p.join(dartDocHostUri, path)
            : liveExampleHref.startsWith('http') || liveExampleHref.isEmpty
                ? liveExampleHref
                : p.join(dartDocHostUri, liveExampleHref),
        this.repoHref = repoHref.isEmpty
            ? '//github.com/dart-lang/site-webdev/tree/master/' + path
            : repoHref;

  factory SyncData.fromJson(String json, {String path}) {
    final data = JSON.decode(json);
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
