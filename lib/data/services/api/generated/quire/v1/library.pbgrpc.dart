// This is a generated file - do not edit.
//
// Generated from quire/v1/library.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'library.pb.dart' as $0;

export 'library.pb.dart';

@$pb.GrpcServiceName('quire.v1.LibraryService')
class LibraryServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  LibraryServiceClient(super.channel, {super.options, super.interceptors});

  /// UC01, create. Registers the metadata of a work. The bytes travel
  /// separately, and the reply says whether this node already holds them.
  $grpc.ResponseFuture<$0.CreateEbookResponse> createEbook(
    $0.CreateEbookRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createEbook, request, options: options);
  }

  /// UC01, read.
  $grpc.ResponseFuture<$0.GetEbookResponse> getEbook(
    $0.GetEbookRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getEbook, request, options: options);
  }

  /// UC01, read — the whole collection, optionally narrowed to one grouping.
  $grpc.ResponseFuture<$0.ListEbooksResponse> listEbooks(
    $0.ListEbooksRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listEbooks, request, options: options);
  }

  /// RF05. UC01 is marked «CRD» because the file itself is not editable; its
  /// metadata is, and this is the RPC that edits it.
  $grpc.ResponseFuture<$0.UpdateEbookResponse> updateEbook(
    $0.UpdateEbookRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateEbook, request, options: options);
  }

  /// UC01, delete. A tombstone, never a removal: a row deleted outright is
  /// resurrected by the next node that had not yet heard about the deletion.
  $grpc.ResponseFuture<$0.DeleteEbookResponse> deleteEbook(
    $0.DeleteEbookRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteEbook, request, options: options);
  }

  /// UC02. Streams the bytes of a work this node does not hold yet. The client
  /// sends the description first and the content after it, so the node can
  /// refuse an oversized or unsupported file before receiving any of it.
  $grpc.ResponseFuture<$0.UploadEbookContentResponse> uploadEbookContent(
    $async.Stream<$0.UploadEbookContentRequest> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$uploadEbookContent, request, options: options)
        .single;
  }

  /// UC02 for a caller that cannot open a client stream.
  ///
  /// A browser is the case these three exist for. gRPC-Web carries a unary call
  /// and a server stream and neither of the other two, so the stream above is
  /// unreachable from one — D10 and D11 in docs/tcc-corrections.md record what
  /// that costs and why this is the answer.
  ///
  /// They differ from the stream in how the bytes arrive and in nothing else.
  /// The description is declared to Begin and checked there, before a byte
  /// travels; the node hashes what it receives as it receives it; and what is
  /// stored is checked against what was declared. The one thing gained is that
  /// an upload addressed by an offset can be resumed, where a stream that died
  /// at nine tenths starts again from nothing.
  $grpc.ResponseFuture<$0.BeginEbookUploadResponse> beginEbookUpload(
    $0.BeginEbookUploadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$beginEbookUpload, request, options: options);
  }

  /// The bytes, one call at a time, each at the offset it continues from.
  ///
  /// A chunk arriving anywhere but at the offset the node is expecting is not
  /// written, and the reply carries the offset it does expect: a caller whose
  /// connection died continues from what arrived, and one that lost a reply and
  /// sent the same chunk again is told so rather than corrupting the file.
  $grpc.ResponseFuture<$0.PutEbookChunkResponse> putEbookChunk(
    $0.PutEbookChunkRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$putEbookChunk, request, options: options);
  }

  /// Ends the upload, checks what arrived against what was declared, and
  /// records that this node holds it.
  $grpc.ResponseFuture<$0.FinishEbookUploadResponse> finishEbookUpload(
    $0.FinishEbookUploadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$finishEbookUpload, request, options: options);
  }

  /// Abandons an upload without finishing it, releasing what the node was
  /// holding. A caller that never sends it is not a leak — the node ends an
  /// upload nobody has sent to for long enough — but a client that has given up
  /// should say so rather than leave a file on the node until it expires.
  $grpc.ResponseFuture<$0.DiscardEbookUploadResponse> discardEbookUpload(
    $0.DiscardEbookUploadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$discardEbookUpload, request, options: options);
  }

  /// Streams the bytes back. A node that replicates this reader without their
  /// files answers that it does not hold them — holding the metadata and not
  /// the file is a state the authorization makes legitimate, not an error.
  $grpc.ResponseStream<$0.DownloadEbookContentResponse> downloadEbookContent(
    $0.DownloadEbookContentRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$downloadEbookContent, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// UC03, create.
  $grpc.ResponseFuture<$0.CreateCollectionResponse> createCollection(
    $0.CreateCollectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createCollection, request, options: options);
  }

  /// UC03, read.
  $grpc.ResponseFuture<$0.GetCollectionResponse> getCollection(
    $0.GetCollectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getCollection, request, options: options);
  }

  /// UC03, read — optionally narrowed to the groupings one work is filed under.
  $grpc.ResponseFuture<$0.ListCollectionsResponse> listCollections(
    $0.ListCollectionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listCollections, request, options: options);
  }

  /// UC03, update.
  $grpc.ResponseFuture<$0.UpdateCollectionResponse> updateCollection(
    $0.UpdateCollectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateCollection, request, options: options);
  }

  /// UC03, delete. A tombstone, for the reason DeleteEbook is one.
  $grpc.ResponseFuture<$0.DeleteCollectionResponse> deleteCollection(
    $0.DeleteCollectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteCollection, request, options: options);
  }

  /// UC03. Files a work under a grouping. Repeating it is not an error: the
  /// pair is unique (C06) and membership is a register that is set, not a row
  /// that is appended.
  $grpc.ResponseFuture<$0.AddEbookToCollectionResponse> addEbookToCollection(
    $0.AddEbookToCollectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addEbookToCollection, request, options: options);
  }

  /// UC03. Clears that register, and is likewise idempotent.
  $grpc.ResponseFuture<$0.RemoveEbookFromCollectionResponse>
      removeEbookFromCollection(
    $0.RemoveEbookFromCollectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeEbookFromCollection, request,
        options: options);
  }

  // method descriptors

  static final _$createEbook =
      $grpc.ClientMethod<$0.CreateEbookRequest, $0.CreateEbookResponse>(
          '/quire.v1.LibraryService/CreateEbook',
          ($0.CreateEbookRequest value) => value.writeToBuffer(),
          $0.CreateEbookResponse.fromBuffer);
  static final _$getEbook =
      $grpc.ClientMethod<$0.GetEbookRequest, $0.GetEbookResponse>(
          '/quire.v1.LibraryService/GetEbook',
          ($0.GetEbookRequest value) => value.writeToBuffer(),
          $0.GetEbookResponse.fromBuffer);
  static final _$listEbooks =
      $grpc.ClientMethod<$0.ListEbooksRequest, $0.ListEbooksResponse>(
          '/quire.v1.LibraryService/ListEbooks',
          ($0.ListEbooksRequest value) => value.writeToBuffer(),
          $0.ListEbooksResponse.fromBuffer);
  static final _$updateEbook =
      $grpc.ClientMethod<$0.UpdateEbookRequest, $0.UpdateEbookResponse>(
          '/quire.v1.LibraryService/UpdateEbook',
          ($0.UpdateEbookRequest value) => value.writeToBuffer(),
          $0.UpdateEbookResponse.fromBuffer);
  static final _$deleteEbook =
      $grpc.ClientMethod<$0.DeleteEbookRequest, $0.DeleteEbookResponse>(
          '/quire.v1.LibraryService/DeleteEbook',
          ($0.DeleteEbookRequest value) => value.writeToBuffer(),
          $0.DeleteEbookResponse.fromBuffer);
  static final _$uploadEbookContent = $grpc.ClientMethod<
          $0.UploadEbookContentRequest, $0.UploadEbookContentResponse>(
      '/quire.v1.LibraryService/UploadEbookContent',
      ($0.UploadEbookContentRequest value) => value.writeToBuffer(),
      $0.UploadEbookContentResponse.fromBuffer);
  static final _$beginEbookUpload = $grpc.ClientMethod<
          $0.BeginEbookUploadRequest, $0.BeginEbookUploadResponse>(
      '/quire.v1.LibraryService/BeginEbookUpload',
      ($0.BeginEbookUploadRequest value) => value.writeToBuffer(),
      $0.BeginEbookUploadResponse.fromBuffer);
  static final _$putEbookChunk =
      $grpc.ClientMethod<$0.PutEbookChunkRequest, $0.PutEbookChunkResponse>(
          '/quire.v1.LibraryService/PutEbookChunk',
          ($0.PutEbookChunkRequest value) => value.writeToBuffer(),
          $0.PutEbookChunkResponse.fromBuffer);
  static final _$finishEbookUpload = $grpc.ClientMethod<
          $0.FinishEbookUploadRequest, $0.FinishEbookUploadResponse>(
      '/quire.v1.LibraryService/FinishEbookUpload',
      ($0.FinishEbookUploadRequest value) => value.writeToBuffer(),
      $0.FinishEbookUploadResponse.fromBuffer);
  static final _$discardEbookUpload = $grpc.ClientMethod<
          $0.DiscardEbookUploadRequest, $0.DiscardEbookUploadResponse>(
      '/quire.v1.LibraryService/DiscardEbookUpload',
      ($0.DiscardEbookUploadRequest value) => value.writeToBuffer(),
      $0.DiscardEbookUploadResponse.fromBuffer);
  static final _$downloadEbookContent = $grpc.ClientMethod<
          $0.DownloadEbookContentRequest, $0.DownloadEbookContentResponse>(
      '/quire.v1.LibraryService/DownloadEbookContent',
      ($0.DownloadEbookContentRequest value) => value.writeToBuffer(),
      $0.DownloadEbookContentResponse.fromBuffer);
  static final _$createCollection = $grpc.ClientMethod<
          $0.CreateCollectionRequest, $0.CreateCollectionResponse>(
      '/quire.v1.LibraryService/CreateCollection',
      ($0.CreateCollectionRequest value) => value.writeToBuffer(),
      $0.CreateCollectionResponse.fromBuffer);
  static final _$getCollection =
      $grpc.ClientMethod<$0.GetCollectionRequest, $0.GetCollectionResponse>(
          '/quire.v1.LibraryService/GetCollection',
          ($0.GetCollectionRequest value) => value.writeToBuffer(),
          $0.GetCollectionResponse.fromBuffer);
  static final _$listCollections =
      $grpc.ClientMethod<$0.ListCollectionsRequest, $0.ListCollectionsResponse>(
          '/quire.v1.LibraryService/ListCollections',
          ($0.ListCollectionsRequest value) => value.writeToBuffer(),
          $0.ListCollectionsResponse.fromBuffer);
  static final _$updateCollection = $grpc.ClientMethod<
          $0.UpdateCollectionRequest, $0.UpdateCollectionResponse>(
      '/quire.v1.LibraryService/UpdateCollection',
      ($0.UpdateCollectionRequest value) => value.writeToBuffer(),
      $0.UpdateCollectionResponse.fromBuffer);
  static final _$deleteCollection = $grpc.ClientMethod<
          $0.DeleteCollectionRequest, $0.DeleteCollectionResponse>(
      '/quire.v1.LibraryService/DeleteCollection',
      ($0.DeleteCollectionRequest value) => value.writeToBuffer(),
      $0.DeleteCollectionResponse.fromBuffer);
  static final _$addEbookToCollection = $grpc.ClientMethod<
          $0.AddEbookToCollectionRequest, $0.AddEbookToCollectionResponse>(
      '/quire.v1.LibraryService/AddEbookToCollection',
      ($0.AddEbookToCollectionRequest value) => value.writeToBuffer(),
      $0.AddEbookToCollectionResponse.fromBuffer);
  static final _$removeEbookFromCollection = $grpc.ClientMethod<
          $0.RemoveEbookFromCollectionRequest,
          $0.RemoveEbookFromCollectionResponse>(
      '/quire.v1.LibraryService/RemoveEbookFromCollection',
      ($0.RemoveEbookFromCollectionRequest value) => value.writeToBuffer(),
      $0.RemoveEbookFromCollectionResponse.fromBuffer);
}

@$pb.GrpcServiceName('quire.v1.LibraryService')
abstract class LibraryServiceBase extends $grpc.Service {
  $core.String get $name => 'quire.v1.LibraryService';

  LibraryServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.CreateEbookRequest, $0.CreateEbookResponse>(
            'CreateEbook',
            createEbook_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CreateEbookRequest.fromBuffer(value),
            ($0.CreateEbookResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetEbookRequest, $0.GetEbookResponse>(
        'GetEbook',
        getEbook_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetEbookRequest.fromBuffer(value),
        ($0.GetEbookResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListEbooksRequest, $0.ListEbooksResponse>(
        'ListEbooks',
        listEbooks_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListEbooksRequest.fromBuffer(value),
        ($0.ListEbooksResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UpdateEbookRequest, $0.UpdateEbookResponse>(
            'UpdateEbook',
            updateEbook_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UpdateEbookRequest.fromBuffer(value),
            ($0.UpdateEbookResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteEbookRequest, $0.DeleteEbookResponse>(
            'DeleteEbook',
            deleteEbook_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteEbookRequest.fromBuffer(value),
            ($0.DeleteEbookResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UploadEbookContentRequest,
            $0.UploadEbookContentResponse>(
        'UploadEbookContent',
        uploadEbookContent,
        true,
        false,
        ($core.List<$core.int> value) =>
            $0.UploadEbookContentRequest.fromBuffer(value),
        ($0.UploadEbookContentResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.BeginEbookUploadRequest,
            $0.BeginEbookUploadResponse>(
        'BeginEbookUpload',
        beginEbookUpload_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.BeginEbookUploadRequest.fromBuffer(value),
        ($0.BeginEbookUploadResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.PutEbookChunkRequest, $0.PutEbookChunkResponse>(
            'PutEbookChunk',
            putEbookChunk_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.PutEbookChunkRequest.fromBuffer(value),
            ($0.PutEbookChunkResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FinishEbookUploadRequest,
            $0.FinishEbookUploadResponse>(
        'FinishEbookUpload',
        finishEbookUpload_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.FinishEbookUploadRequest.fromBuffer(value),
        ($0.FinishEbookUploadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DiscardEbookUploadRequest,
            $0.DiscardEbookUploadResponse>(
        'DiscardEbookUpload',
        discardEbookUpload_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DiscardEbookUploadRequest.fromBuffer(value),
        ($0.DiscardEbookUploadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DownloadEbookContentRequest,
            $0.DownloadEbookContentResponse>(
        'DownloadEbookContent',
        downloadEbookContent_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.DownloadEbookContentRequest.fromBuffer(value),
        ($0.DownloadEbookContentResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateCollectionRequest,
            $0.CreateCollectionResponse>(
        'CreateCollection',
        createCollection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateCollectionRequest.fromBuffer(value),
        ($0.CreateCollectionResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetCollectionRequest, $0.GetCollectionResponse>(
            'GetCollection',
            getCollection_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetCollectionRequest.fromBuffer(value),
            ($0.GetCollectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListCollectionsRequest,
            $0.ListCollectionsResponse>(
        'ListCollections',
        listCollections_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListCollectionsRequest.fromBuffer(value),
        ($0.ListCollectionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateCollectionRequest,
            $0.UpdateCollectionResponse>(
        'UpdateCollection',
        updateCollection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateCollectionRequest.fromBuffer(value),
        ($0.UpdateCollectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteCollectionRequest,
            $0.DeleteCollectionResponse>(
        'DeleteCollection',
        deleteCollection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteCollectionRequest.fromBuffer(value),
        ($0.DeleteCollectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddEbookToCollectionRequest,
            $0.AddEbookToCollectionResponse>(
        'AddEbookToCollection',
        addEbookToCollection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.AddEbookToCollectionRequest.fromBuffer(value),
        ($0.AddEbookToCollectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RemoveEbookFromCollectionRequest,
            $0.RemoveEbookFromCollectionResponse>(
        'RemoveEbookFromCollection',
        removeEbookFromCollection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RemoveEbookFromCollectionRequest.fromBuffer(value),
        ($0.RemoveEbookFromCollectionResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.CreateEbookResponse> createEbook_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateEbookRequest> $request) async {
    return createEbook($call, await $request);
  }

  $async.Future<$0.CreateEbookResponse> createEbook(
      $grpc.ServiceCall call, $0.CreateEbookRequest request);

  $async.Future<$0.GetEbookResponse> getEbook_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetEbookRequest> $request) async {
    return getEbook($call, await $request);
  }

  $async.Future<$0.GetEbookResponse> getEbook(
      $grpc.ServiceCall call, $0.GetEbookRequest request);

  $async.Future<$0.ListEbooksResponse> listEbooks_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListEbooksRequest> $request) async {
    return listEbooks($call, await $request);
  }

  $async.Future<$0.ListEbooksResponse> listEbooks(
      $grpc.ServiceCall call, $0.ListEbooksRequest request);

  $async.Future<$0.UpdateEbookResponse> updateEbook_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateEbookRequest> $request) async {
    return updateEbook($call, await $request);
  }

  $async.Future<$0.UpdateEbookResponse> updateEbook(
      $grpc.ServiceCall call, $0.UpdateEbookRequest request);

  $async.Future<$0.DeleteEbookResponse> deleteEbook_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteEbookRequest> $request) async {
    return deleteEbook($call, await $request);
  }

  $async.Future<$0.DeleteEbookResponse> deleteEbook(
      $grpc.ServiceCall call, $0.DeleteEbookRequest request);

  $async.Future<$0.UploadEbookContentResponse> uploadEbookContent(
      $grpc.ServiceCall call,
      $async.Stream<$0.UploadEbookContentRequest> request);

  $async.Future<$0.BeginEbookUploadResponse> beginEbookUpload_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.BeginEbookUploadRequest> $request) async {
    return beginEbookUpload($call, await $request);
  }

  $async.Future<$0.BeginEbookUploadResponse> beginEbookUpload(
      $grpc.ServiceCall call, $0.BeginEbookUploadRequest request);

  $async.Future<$0.PutEbookChunkResponse> putEbookChunk_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PutEbookChunkRequest> $request) async {
    return putEbookChunk($call, await $request);
  }

  $async.Future<$0.PutEbookChunkResponse> putEbookChunk(
      $grpc.ServiceCall call, $0.PutEbookChunkRequest request);

  $async.Future<$0.FinishEbookUploadResponse> finishEbookUpload_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.FinishEbookUploadRequest> $request) async {
    return finishEbookUpload($call, await $request);
  }

  $async.Future<$0.FinishEbookUploadResponse> finishEbookUpload(
      $grpc.ServiceCall call, $0.FinishEbookUploadRequest request);

  $async.Future<$0.DiscardEbookUploadResponse> discardEbookUpload_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DiscardEbookUploadRequest> $request) async {
    return discardEbookUpload($call, await $request);
  }

  $async.Future<$0.DiscardEbookUploadResponse> discardEbookUpload(
      $grpc.ServiceCall call, $0.DiscardEbookUploadRequest request);

  $async.Stream<$0.DownloadEbookContentResponse> downloadEbookContent_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DownloadEbookContentRequest> $request) async* {
    yield* downloadEbookContent($call, await $request);
  }

  $async.Stream<$0.DownloadEbookContentResponse> downloadEbookContent(
      $grpc.ServiceCall call, $0.DownloadEbookContentRequest request);

  $async.Future<$0.CreateCollectionResponse> createCollection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CreateCollectionRequest> $request) async {
    return createCollection($call, await $request);
  }

  $async.Future<$0.CreateCollectionResponse> createCollection(
      $grpc.ServiceCall call, $0.CreateCollectionRequest request);

  $async.Future<$0.GetCollectionResponse> getCollection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetCollectionRequest> $request) async {
    return getCollection($call, await $request);
  }

  $async.Future<$0.GetCollectionResponse> getCollection(
      $grpc.ServiceCall call, $0.GetCollectionRequest request);

  $async.Future<$0.ListCollectionsResponse> listCollections_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListCollectionsRequest> $request) async {
    return listCollections($call, await $request);
  }

  $async.Future<$0.ListCollectionsResponse> listCollections(
      $grpc.ServiceCall call, $0.ListCollectionsRequest request);

  $async.Future<$0.UpdateCollectionResponse> updateCollection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateCollectionRequest> $request) async {
    return updateCollection($call, await $request);
  }

  $async.Future<$0.UpdateCollectionResponse> updateCollection(
      $grpc.ServiceCall call, $0.UpdateCollectionRequest request);

  $async.Future<$0.DeleteCollectionResponse> deleteCollection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteCollectionRequest> $request) async {
    return deleteCollection($call, await $request);
  }

  $async.Future<$0.DeleteCollectionResponse> deleteCollection(
      $grpc.ServiceCall call, $0.DeleteCollectionRequest request);

  $async.Future<$0.AddEbookToCollectionResponse> addEbookToCollection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.AddEbookToCollectionRequest> $request) async {
    return addEbookToCollection($call, await $request);
  }

  $async.Future<$0.AddEbookToCollectionResponse> addEbookToCollection(
      $grpc.ServiceCall call, $0.AddEbookToCollectionRequest request);

  $async.Future<$0.RemoveEbookFromCollectionResponse>
      removeEbookFromCollection_Pre($grpc.ServiceCall $call,
          $async.Future<$0.RemoveEbookFromCollectionRequest> $request) async {
    return removeEbookFromCollection($call, await $request);
  }

  $async.Future<$0.RemoveEbookFromCollectionResponse> removeEbookFromCollection(
      $grpc.ServiceCall call, $0.RemoveEbookFromCollectionRequest request);
}
