module UniFed
  # UniFed Nigeria — Digital University Operating System (Rails modular monolith)
  #
  # Architecture (ADR-0002): Domain-Driven Design modular monolith.
  # Bounded contexts live under app/contexts and communicate only through
  # explicit ports/gateways and the domain event bus — never direct AR joins.
  #
  # Contexts:
  #   Identity    — users, OIDC, MFA, roles            (ADR-0004)
  #   Academic    — University/Faculty/.../Course      (ADR-0005)
  #   Records     — grades, transcripts                 (Slice 1)
  #   StudentId   — digital student ID issuance/verify  (Slice 1)
  #   Federation  — ActivityPub actors/inbox/outbox     (ADR-0003)
  module Contexts
  end
end
