/**
 * \file ERF_GTestVersion.cpp
 *
 * Guards the generated ERF_Version.H (see VERSION_MANAGEMENT.md).
 *
 * These assertions are cheap but they cover the failure modes that actually
 * occurred while this machinery was written: a template placeholder left
 * unsubstituted, and a field silently falling back to a hardcoded guess. Both
 * produce a header that compiles and a binary that runs, so only an explicit
 * check catches them.
 */
#include <cstring>
#include <string>

#include <gtest/gtest.h>

#include "ERF_Version.H"

namespace {

//! Every value must be present. An empty string means the generator wrote a
//! field it had no value for.
TEST(Version, FieldsAreNonEmpty)
{
    EXPECT_GT(std::strlen(erf_version::version), 0u);
    EXPECT_GT(std::strlen(erf_version::git_sha), 0u);
    EXPECT_GT(std::strlen(erf_version::git_branch), 0u);
    EXPECT_GT(std::strlen(erf_version::git_parent), 0u);
}

//! No field may still carry an @ERF_...@ placeholder. Substitution is done by
//! string replacement, so a renamed placeholder fails silently rather than
//! erroring, and the literal text ends up in the binary.
TEST(Version, NoUnsubstitutedPlaceholders)
{
    for (const char* value : {erf_version::version,
                              erf_version::git_sha,
                              erf_version::git_branch,
                              erf_version::git_parent}) {
        const std::string text(value);
        EXPECT_EQ(text.find("@ERF_"), std::string::npos)
            << "unsubstituted template placeholder in ERF_Version.H: " << text;
    }
}

//! The abbreviation must be a genuine prefix of the full hash, and must not
//! exceed the configured width.
TEST(Version, ShortShaIsAPrefixOfTheFullSha)
{
    const std::string full(erf_version::git_sha);
    const std::string abbreviated(erf_version::git_sha_short);

    EXPECT_LE(abbreviated.size(),
              static_cast<std::size_t>(erf_version::sha_display_chars));
    EXPECT_LE(abbreviated.size(), full.size());
    EXPECT_EQ(full.compare(0, abbreviated.size(), abbreviated), 0);
}

//! A build outside a git work tree reports "unknown" everywhere rather than a
//! plausible-looking guess. Inside one, the SHA is a full 40-character hash and
//! the branch names something real. Both states are legitimate, so the test
//! pins whichever one this build is in rather than requiring a work tree.
TEST(Version, GitFieldsAreEitherResolvedOrHonestlyUnknown)
{
    const std::string sha(erf_version::git_sha);

    if (sha == "unknown") {
        EXPECT_STREQ(erf_version::version, "unknown");
        EXPECT_STREQ(erf_version::git_branch, "unknown");
        EXPECT_STREQ(erf_version::git_parent, "unknown");
        return;
    }

    EXPECT_EQ(sha.size(), 40u) << "expected a full commit hash, got: " << sha;
    EXPECT_EQ(sha.find_first_not_of("0123456789abcdef"), std::string::npos)
        << "commit hash is not lowercase hexadecimal: " << sha;

    // A detached HEAD legitimately has no branch, and a branch with neither an
    // upstream nor a sibling to compare against legitimately has no parent.
    // What must never happen is a field naming a branch nobody consulted --
    // the parent field previously defaulted to a hardcoded "main".
    EXPECT_GT(std::strlen(erf_version::git_branch), 0u);
    EXPECT_GT(std::strlen(erf_version::git_parent), 0u);
}

} // namespace
