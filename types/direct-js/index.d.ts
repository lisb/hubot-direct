// Copyright (c) 2023 L is B Corp.
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

declare namespace DirectJs {
  interface Int64 {
    high: number;
    low: number;
  }

  interface User {
    id: string;
    id_i64: Int64;
    name: string;
    displayName: string;
    canonicalDisplayName: string;
    phoneticDisplayName: string | null;
    canonicalPhoneticDisplayName: string | null;
    email?: string;
    profile_url?: string;
    updatedAt: Int64;
  }

  interface Domain {
    id: string;
    id_i64: Int64;
    domainInfo: {
      name: string;
      logoUrl: string | null;
      frozen: boolean;
    };
    closed: boolean;
    contract: any; // TODO
    profileDefinition: any; // TODO
    setting: any; // TODO
    role: any; // TODO
  }

  enum TalkType {
    Unknown = 0,
    Pair = 1,
    Group = 2,
  }

  interface Talk {
    id: string;
    id_i64: Int64;
    domainId: string;
    domainId_i64: Int64;
    type: TalkType;
    name: string | null;
    topic: string | null;
    iconUrl: string | null;
    userIds: Int64[];
    guestIds: null;
    leftUsers: any[]; // TODO
    users: User[];
    domain: Domain;
    updatedAt: Int64;
  }

  type RemoteFile = {
    id: string;
    name: string;
    content_type: string;
    content_size: number;
    url: string;
  };
}

export = DirectJs;
export as namespace DirectJs;
