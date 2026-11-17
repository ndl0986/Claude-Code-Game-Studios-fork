package com.galaxyandsun.daidatanhhung.core

/**
 * R12, the claim gate (content/README.md, fixtures/claim-gate.json).
 * A claim counts as signed only when it exists and its status is "approved".
 */
object ClaimGate {
    data class Result(val releaseBuildPasses: Boolean, val runtimeShow: Boolean, val debugBadges: List<String>)

    /** [statuses]: claim id → sign-off status. [textClaims]: the claims cited by each bundled Text. */
    fun evaluate(statuses: Map<String, String>, textClaims: List<List<String>>): Result {
        val unsigned = textClaims.flatten().distinct().filter { statuses[it] != "approved" }.sorted()
        val ok = unsigned.isEmpty()
        return Result(releaseBuildPasses = ok, runtimeShow = ok, debugBadges = unsigned)
    }

    /** Claim ids in [claims] that are not approved in [statuses] (the badge on one Text). */
    fun unsigned(statuses: Map<String, String>, claims: List<String>): List<String> =
        claims.filter { statuses[it] != "approved" }
}
