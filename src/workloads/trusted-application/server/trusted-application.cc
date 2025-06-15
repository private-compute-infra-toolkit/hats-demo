// Copyright 2024 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "workloads/trusted-application/server/trusted-application.h"

#include <string>

#include "grpcpp/grpcpp.h"
#include "client/proto/orchestrator.pb.h"
#include "workloads/trusted-application/proto/trusted_service.grpc.pb.h"
#include "workloads/trusted-application/proto/trusted_service.pb.h"
#include "crypto/aead-crypter.h"
#include "crypto/secret-data.h"

using privacy_sandbox::crypto::SecretData;
using privacy_sandbox::server_common::Key;

namespace privacy_sandbox::client {

grpc::Status TrustedApplication::Echo(grpc::ServerContext* context,
                                      const EncryptedRequest* request,
                                      DecryptedResponse* response) {
  // Create a gRPC channel to the second server and forward the request.
  if (!request->forwarding_address().empty()) {
    auto stub = TrustedService::NewStub(
        grpc::CreateChannel(
          request->forwarding_address(),
          grpc::InsecureChannelCredentials()));
    EncryptedRequest forwarded = *request;
    forwarded.clear_forwarding_address();
    return stub->Echo(
        grpc::ClientContext::FromServerContext(*context).get(),
        forwarded,
        response);
  }

  // Otherwise, decrypt the data within this server.
  Key key_to_use;
  bool key_found = false;
  for (const Key& key : keys_) {
    if (key.key_id() == request->key_id()) {
      key_to_use = key;
      key_found = true;
      break;
    }
  }

  if (!key_found) {
    return grpc::Status(
        grpc::StatusCode::UNKNOWN,
        absl::StrCat("Decryption key not found, key id: ", request->key_id()));
  }

  SecretData decryption_key = SecretData(key_to_use.private_key());

  SecretData encrypted_data = SecretData(request->encrypted_message());
  absl::StatusOr<SecretData> decrypted = privacy_sandbox::crypto::Decrypt(
      decryption_key, encrypted_data, privacy_sandbox::crypto::kSecretAd);
  if (!decrypted.ok()) {
    return grpc::Status(grpc::StatusCode::INTERNAL, std::string(
          decrypted.status().message()));
  }
  *response->mutable_response() = (*decrypted).GetStringView();

  return grpc::Status::OK;
}

}  // namespace privacy_sandbox::client
