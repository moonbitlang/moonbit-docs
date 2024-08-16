import fs from 'node:fs/promises'
import * as utils from '../lib/utils.js'
import path from 'node:path'
import * as process from 'process'
;(async () => {
  const githubStars = await utils.getGithubStars()
  const contributors = await utils.getContributors()
  const commitCount = await utils.getCommitCount()
  const mergedPRCount = await utils.getMergedPRCount()
  const contributorsCount = contributors.length
  const data = JSON.stringify(
    {
      githubStars: `${githubStars}`,
      contributors,
      commitCount,
      mergedPRCount: `${mergedPRCount}`,
      contributorsCount: `${contributorsCount}`
    },
    null,
    2
  )
  let hasDir = true
  const dir = path.join(process.cwd(), 'data')
  try {
    await fs.access(dir)
  } catch (e) {
    hasDir = false
  }
  if (!hasDir) {
    await fs.mkdir(dir)
  }
  console.log(data)
  await fs.writeFile(path.join(process.cwd(), 'data', 'data.json'), data)
})()
