async function getGithubStars() {
  return await fetch('https://api.github.com/repos/moonbitlang/moonbit-docs')
    .then((res) => res.json())
    .then((data) => data.watchers_count)
}

async function getContributors() {
  return await fetch(
    'https://api.github.com/repos/moonbitlang/core/contributors'
  ).then((res) => res.json())
}

async function getCommitCount() {
  const res = await fetch(
    'https://api.github.com/repos/moonbitlang/core/commits?per_page=1',
    {
      method: 'HEAD'
    }
  )
  const link = res.headers.get('link')
  return link?.match(/page=(\d+)>; rel="last"/)?.[1]
}

async function getMergedPRCount() {
  return await fetch(
    'https://api.github.com/search/issues?q=repo:moonbitlang/core+is:pr+is:merged'
  )
    .then((res) => res.json())
    .then((json) => json.total_count)
}

export { getGithubStars, getContributors, getCommitCount, getMergedPRCount }
