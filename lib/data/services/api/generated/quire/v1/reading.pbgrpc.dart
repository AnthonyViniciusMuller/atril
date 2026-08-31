// This is a generated file - do not edit.
//
// Generated from quire/v1/reading.proto.

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

import 'reading.pb.dart' as $0;

export 'reading.pb.dart';

@$pb.GrpcServiceName('quire.v1.ReadingService')
class ReadingServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ReadingServiceClient(super.channel, {super.options, super.interceptors});

  /// UC04, create.
  $grpc.ResponseFuture<$0.CreateAnnotationResponse> createAnnotation(
    $0.CreateAnnotationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createAnnotation, request, options: options);
  }

  /// UC04, read.
  $grpc.ResponseFuture<$0.GetAnnotationResponse> getAnnotation(
    $0.GetAnnotationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAnnotation, request, options: options);
  }

  /// UC04, read — everything written in one work.
  $grpc.ResponseFuture<$0.ListAnnotationsResponse> listAnnotations(
    $0.ListAnnotationsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listAnnotations, request, options: options);
  }

  /// UC04, update. An annotation edited from a second device is why
  /// Revision.device_id has to mean the last writer rather than the originator
  /// (C10): after this call the two are different devices, and the tie-break
  /// needs the one whose write the record reflects.
  $grpc.ResponseFuture<$0.UpdateAnnotationResponse> updateAnnotation(
    $0.UpdateAnnotationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateAnnotation, request, options: options);
  }

  /// UC04, delete. A tombstone, so that a node which had not yet heard about the
  /// deletion cannot resurrect the annotation by replying with its own copy.
  $grpc.ResponseFuture<$0.DeleteAnnotationResponse> deleteAnnotation(
    $0.DeleteAnnotationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteAnnotation, request, options: options);
  }

  /// UC05. Records where the calling device has reached in a work, creating the
  /// row on first use and overwriting it afterwards — one row per work and
  /// device, as Quadro 21 specifies.
  ///
  /// A device writes its own position and no other device's. RN10 already
  /// requires that of every operation, and here it is also what makes the entity
  /// conflict-free.
  $grpc.ResponseFuture<$0.UpdateReadingProgressResponse> updateReadingProgress(
    $0.UpdateReadingProgressRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateReadingProgress, request, options: options);
  }

  /// UC05, RN01. Every device's position in one work, which is what a client
  /// needs to decide what to show the reader: the furthest position, the most
  /// recent one, or a prompt asking which to resume from. That decision belongs
  /// to the client, so the server does not make it by returning only one row.
  $grpc.ResponseFuture<$0.ListReadingProgressResponse> listReadingProgress(
    $0.ListReadingProgressRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listReadingProgress, request, options: options);
  }

  // method descriptors

  static final _$createAnnotation = $grpc.ClientMethod<
          $0.CreateAnnotationRequest, $0.CreateAnnotationResponse>(
      '/quire.v1.ReadingService/CreateAnnotation',
      ($0.CreateAnnotationRequest value) => value.writeToBuffer(),
      $0.CreateAnnotationResponse.fromBuffer);
  static final _$getAnnotation =
      $grpc.ClientMethod<$0.GetAnnotationRequest, $0.GetAnnotationResponse>(
          '/quire.v1.ReadingService/GetAnnotation',
          ($0.GetAnnotationRequest value) => value.writeToBuffer(),
          $0.GetAnnotationResponse.fromBuffer);
  static final _$listAnnotations =
      $grpc.ClientMethod<$0.ListAnnotationsRequest, $0.ListAnnotationsResponse>(
          '/quire.v1.ReadingService/ListAnnotations',
          ($0.ListAnnotationsRequest value) => value.writeToBuffer(),
          $0.ListAnnotationsResponse.fromBuffer);
  static final _$updateAnnotation = $grpc.ClientMethod<
          $0.UpdateAnnotationRequest, $0.UpdateAnnotationResponse>(
      '/quire.v1.ReadingService/UpdateAnnotation',
      ($0.UpdateAnnotationRequest value) => value.writeToBuffer(),
      $0.UpdateAnnotationResponse.fromBuffer);
  static final _$deleteAnnotation = $grpc.ClientMethod<
          $0.DeleteAnnotationRequest, $0.DeleteAnnotationResponse>(
      '/quire.v1.ReadingService/DeleteAnnotation',
      ($0.DeleteAnnotationRequest value) => value.writeToBuffer(),
      $0.DeleteAnnotationResponse.fromBuffer);
  static final _$updateReadingProgress = $grpc.ClientMethod<
          $0.UpdateReadingProgressRequest, $0.UpdateReadingProgressResponse>(
      '/quire.v1.ReadingService/UpdateReadingProgress',
      ($0.UpdateReadingProgressRequest value) => value.writeToBuffer(),
      $0.UpdateReadingProgressResponse.fromBuffer);
  static final _$listReadingProgress = $grpc.ClientMethod<
          $0.ListReadingProgressRequest, $0.ListReadingProgressResponse>(
      '/quire.v1.ReadingService/ListReadingProgress',
      ($0.ListReadingProgressRequest value) => value.writeToBuffer(),
      $0.ListReadingProgressResponse.fromBuffer);
}

@$pb.GrpcServiceName('quire.v1.ReadingService')
abstract class ReadingServiceBase extends $grpc.Service {
  $core.String get $name => 'quire.v1.ReadingService';

  ReadingServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CreateAnnotationRequest,
            $0.CreateAnnotationResponse>(
        'CreateAnnotation',
        createAnnotation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateAnnotationRequest.fromBuffer(value),
        ($0.CreateAnnotationResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetAnnotationRequest, $0.GetAnnotationResponse>(
            'GetAnnotation',
            getAnnotation_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetAnnotationRequest.fromBuffer(value),
            ($0.GetAnnotationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListAnnotationsRequest,
            $0.ListAnnotationsResponse>(
        'ListAnnotations',
        listAnnotations_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListAnnotationsRequest.fromBuffer(value),
        ($0.ListAnnotationsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateAnnotationRequest,
            $0.UpdateAnnotationResponse>(
        'UpdateAnnotation',
        updateAnnotation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateAnnotationRequest.fromBuffer(value),
        ($0.UpdateAnnotationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteAnnotationRequest,
            $0.DeleteAnnotationResponse>(
        'DeleteAnnotation',
        deleteAnnotation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteAnnotationRequest.fromBuffer(value),
        ($0.DeleteAnnotationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateReadingProgressRequest,
            $0.UpdateReadingProgressResponse>(
        'UpdateReadingProgress',
        updateReadingProgress_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateReadingProgressRequest.fromBuffer(value),
        ($0.UpdateReadingProgressResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListReadingProgressRequest,
            $0.ListReadingProgressResponse>(
        'ListReadingProgress',
        listReadingProgress_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListReadingProgressRequest.fromBuffer(value),
        ($0.ListReadingProgressResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.CreateAnnotationResponse> createAnnotation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CreateAnnotationRequest> $request) async {
    return createAnnotation($call, await $request);
  }

  $async.Future<$0.CreateAnnotationResponse> createAnnotation(
      $grpc.ServiceCall call, $0.CreateAnnotationRequest request);

  $async.Future<$0.GetAnnotationResponse> getAnnotation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetAnnotationRequest> $request) async {
    return getAnnotation($call, await $request);
  }

  $async.Future<$0.GetAnnotationResponse> getAnnotation(
      $grpc.ServiceCall call, $0.GetAnnotationRequest request);

  $async.Future<$0.ListAnnotationsResponse> listAnnotations_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListAnnotationsRequest> $request) async {
    return listAnnotations($call, await $request);
  }

  $async.Future<$0.ListAnnotationsResponse> listAnnotations(
      $grpc.ServiceCall call, $0.ListAnnotationsRequest request);

  $async.Future<$0.UpdateAnnotationResponse> updateAnnotation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateAnnotationRequest> $request) async {
    return updateAnnotation($call, await $request);
  }

  $async.Future<$0.UpdateAnnotationResponse> updateAnnotation(
      $grpc.ServiceCall call, $0.UpdateAnnotationRequest request);

  $async.Future<$0.DeleteAnnotationResponse> deleteAnnotation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteAnnotationRequest> $request) async {
    return deleteAnnotation($call, await $request);
  }

  $async.Future<$0.DeleteAnnotationResponse> deleteAnnotation(
      $grpc.ServiceCall call, $0.DeleteAnnotationRequest request);

  $async.Future<$0.UpdateReadingProgressResponse> updateReadingProgress_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateReadingProgressRequest> $request) async {
    return updateReadingProgress($call, await $request);
  }

  $async.Future<$0.UpdateReadingProgressResponse> updateReadingProgress(
      $grpc.ServiceCall call, $0.UpdateReadingProgressRequest request);

  $async.Future<$0.ListReadingProgressResponse> listReadingProgress_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListReadingProgressRequest> $request) async {
    return listReadingProgress($call, await $request);
  }

  $async.Future<$0.ListReadingProgressResponse> listReadingProgress(
      $grpc.ServiceCall call, $0.ListReadingProgressRequest request);
}
