import 'dart:convert';

import 'package:dart_doc_syncer/example2uri.dart';
import 'package:path/path.dart' as p;

import 'options.dart';

/// Holds metadata about the example application that is used to generate a
/// README file.
class SyncData {
  final String name; // e.g., 'architecture'
  final String title; // e.g. 'Architecture Overview'
  final String docPart; // e.g. 'guide' (from 'guide/architecture')
  final String docHref;
  final String repoHref;
  final String liveExampleHref;
  final List<String> links;

  String get id =>
      p.join(docPart, name); // e.g. 'quickstart' or 'guide/architecture'

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
        this.docPart = docPart,
        this.docHref = docHref.isEmpty
            ? p.join(dartDocUriPrefix, docPart, '${getExampleName(path)}.html')
            : docHref.startsWith('http')
                ? docHref
                : p.join(dartDocUriPrefix, docPart, docHref),
        this.liveExampleHref = liveExampleHref.isEmpty
            ? p.join(exampleHostUriPrefix, getExampleName(path))
            : liveExampleHref.startsWith('http')
                ? liveExampleHref
                : p.join(exampleHostUriPrefix, liveExampleHref),
        this.repoHref = repoHref.isEmpty
            ? '//github.com/angular/angular.io/tree/master/' + path
            : repoHref;

  factory SyncData.fromJson(String json, {String path}) {
    final data = JSON.decode(json);
    return new SyncData(
        name: data['name'] ?? '',
        title: data['title'] ?? '',
        docPart: data['docPart'] ?? '',
        docHref: data['docHref'] ?? '',
        repoHref: data['repoHref'] ?? '',
        liveExampleHref: data['liveExampleHref'] ?? '',
        links: data['links'] ?? [],
        path: path);
  }
}
