import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const pinnedGaiaHead = 'c94df3f5a53cd9f472e8a97b656dc23d7c940389';
const gaiaRoot = process.env.GAIA_REPO;
if (!gaiaRoot) throw new Error('Set GAIA_REPO to a checkout of the pinned Gaia revision.');

const cwd = resolve(gaiaRoot);
const git = (...args) => execFileSync('git', args, { cwd, encoding: 'utf8' }).trim();
assert.equal(git('rev-parse', 'HEAD'), pinnedGaiaHead, 'Gaia revision changed');
assert.equal(
  git('status', '--porcelain', '--', 'src/github-portfolio-publication.mjs'),
  '',
  'The pinned publication seam must be unmodified',
);

const { createGitHubCandidatePublicationAdapter, GitHubCandidatePublicationError } =
  await import(pathToFileURL(join(cwd, 'src', 'github-portfolio-publication.mjs')).href);

const canonicalJson = (value) => {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(',')}]`;
  if (value && typeof value === 'object') {
    return `{${Object.keys(value).sort().map(
      (key) => `${JSON.stringify(key)}:${canonicalJson(value[key])}`,
    ).join(',')}}`;
  }
  return JSON.stringify(value);
};
const sha256 = (value) => createHash('sha256').update(canonicalJson(value)).digest('hex');
const headOid = '1'.repeat(40);
const commitOid = '2'.repeat(40);
const body = {
  schema: 'gaia-github-candidate-publish-intent/1',
  effect: 'NONE',
  source: {
    transitionRevision: 'a'.repeat(64),
    executionReceiptRevision: 'b'.repeat(64),
    intentRevision: 'c'.repeat(64),
    portfolioRevision: 'd'.repeat(64),
    idempotencyKey: 'e'.repeat(64),
  },
  repository: 'GuitarAlchemist/gaia',
  item: { kind: 'ISSUE', id: 'I_synthetic', number: 42 },
  candidate: {
    headOid,
    baseOid: headOid,
    changeSetIdentity: 'f'.repeat(64),
    observation: 'CALLER_OBSERVED_READ_ONLY_DATA',
  },
  requestedOperations: [
    'COMMIT_CANDIDATE', 'PUSH_CANDIDATE_BRANCH', 'OPEN_PULL_REQUEST',
  ],
};
const intent = { ...body, revision: sha256(body) };

function adapterFor(authorizedRevision, calls) {
  return createGitHubCandidatePublicationAdapter({
    expectedRepository: intent.repository,
    authority: {
      async consume() {
        calls.push('consume');
        return {
          status: 'AUTHORIZED', grantId: 'synthetic-grant',
          intentRevision: authorizedRevision,
        };
      },
    },
    effects: {
      async observe() {
        calls.push('observe');
        return {
          repository: intent.repository,
          headOid,
          baseOid: headOid,
          changeSetIdentity: intent.candidate.changeSetIdentity,
        };
      },
      async commit() { calls.push('commit'); return { commitOid }; },
      async push() { calls.push('push'); return { headOid: commitOid }; },
      async openPullRequest() {
        calls.push('openPullRequest');
        return {
          number: 17,
          url: 'https://github.com/GuitarAlchemist/gaia/pull/17',
          headOid: commitOid,
        };
      },
    },
  });
}

const refusedCalls = [];
await assert.rejects(
  adapterFor('0'.repeat(64), refusedCalls).publish({ intent, grant: { synthetic: true } }),
  (error) => error instanceof GitHubCandidatePublicationError
    && error.code === 'AuthorityInvalid',
);
assert.deepEqual(refusedCalls, ['observe', 'consume']);

const acceptedCalls = [];
const receipt = await adapterFor(intent.revision, acceptedCalls).publish({
  intent, grant: { synthetic: true },
});
assert.deepEqual(acceptedCalls, [
  'observe', 'consume', 'commit', 'push', 'openPullRequest',
]);
assert.equal(receipt.status, 'completed');
assert.equal(receipt.intentRevision, intent.revision);

console.log(JSON.stringify({
  gaiaHead: pinnedGaiaHead,
  seam: 'createGitHubCandidatePublicationAdapter.publish',
  mismatchedRevision: { outcome: 'AuthorityInvalid', calls: refusedCalls },
  matchingRevision: { outcome: receipt.status, calls: acceptedCalls },
  externalEffects: 'none; injected functions only',
}, null, 2));
