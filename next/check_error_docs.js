#!/usr/bin/env node
// @ts-check
/**
 * 检查 error code 文档的脚本
 * 用法: node check_error_docs.js [error_code]
 * 
 * 功能:
 * 1. 检查指定的 error code 文档是否存在
 * 2. 验证 xxxx_error 是否产生对应的 warning 或 error
 * 3. 验证 xxxx_fixed 是否没有任何 warning 或 error
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const ERROR_CODES_DIR = 'language/error_codes';

/**
 * 执行 moon test 命令并返回结果
 * @param {string} filePath - 要测试的文件路径
 * @param {string|undefined} errorCode - 错误代码 (如果是数字，则表示预期的错误代码)
 * @returns {{exitSuccess: boolean, output: string, error: string, hasExpected: boolean}} - 测试结果
 */
function runMoonTest(filePath, errorCode = undefined) {
  try {
    const result = execSync(`moon test -C "${filePath}" 2>&1`, {
      encoding: 'utf8',
      cwd: process.cwd(),
      stdio: 'pipe',
      env: {
        ...process.env,
        "NO_COLOR": "1", // 禁用颜色输出
      }
    });

    const hasWarnings = /Warning: \[\d{4}\]/i.test(result);
    const hasErrors = /Error: \[\d{4}\]/i.test(result) && !/Total tests:.*failed: 0/.test(result);

    let hasExpected = false;

    if (errorCode) {
      const errorCodeNum = Number(errorCode);
      if (errorCodeNum < 3000) {
        // 期望警告：检查是否有对应的警告代码
        const errorCodePadded = errorCode.padStart(4, '0');
        const errorPattern = new RegExp(`Warning: \\[${errorCodePadded}\\]`);
        hasExpected = errorPattern.test(result);
      } else {
        // 期望错误：这种情况不应该到达这里，因为错误会导致 execSync 抛出异常
        hasExpected = false;
      }
    } else {
      // 不期望任何错误或警告
      hasExpected = !hasWarnings && !hasErrors;
    }

    return {
      exitSuccess: true,
      output: result,
      error: '',
      hasExpected,
    };
  } catch (error) {
    // moon test 命令失败了
    const output = error.stdout ? error.stdout.toString() : '';
    const stderr = error.stderr ? error.stderr.toString() : '';
    const combinedOutput = output + stderr;

    let hasExpected = false;

    if (errorCode) {
      const errorCodeNum = Number(errorCode);
      if (errorCodeNum >= 3000) {
        // 期望错误：检查是否有对应的错误代码
        const errorCodePadded = errorCode.padStart(4, '0');
        const errorPattern = new RegExp(`Error: \\[${errorCodePadded}\\]`);
        hasExpected = errorPattern.test(combinedOutput);
      } else {
        // 期望警告但命令失败了，这是意外的
        hasExpected = false;
      }
    } else {
      // 不期望任何错误，但命令失败了
      hasExpected = false;
    }

    return {
      exitSuccess: false,
      output: combinedOutput,
      error: error.message || '',
      hasExpected,
    };
  }
}

/**
 * 检查特定的 error code 文档
 * @param {string} errorCode - 错误代码 (例如: E0001)
 * @returns {Object} - 检查结果
 */
function checkErrorCode(errorCode) {
  console.log(`🔍 检查错误代码: ${errorCode}`);

  const errorExamplePath = path.join(ERROR_CODES_DIR, `${errorCode}_error`);
  const fixExamplePath = path.join(ERROR_CODES_DIR, `${errorCode}_fixed`);

  const result = {
    errorCode,
    mbtMdExists: fs.existsSync(errorExamplePath),
    suggestionExists: fs.existsSync(fixExamplePath),
    mbtMdTest: { exitSuccess: false, output: '', error: '', hasExpected: false },
    suggestionTest: { exitSuccess: false, output: '', error: '', hasExpected: false },
    overall: 'unknown'
  };

  // 检查文件是否存在
  if (!result.mbtMdExists) {
    console.log(`❌ ${errorCode}_error 不存在`);
    result.overall = 'missing_files';
    return result;
  }

  if (!result.suggestionExists) {
    console.log(`❌ ${errorCode}_fixed 不存在`);
    result.overall = 'missing_files';
    return result;
  }

  console.log(`✅ 两个文件都存在`);

  // 测试 xxxx_error - 应该产生 warning 或 error
  console.log(`🧪 测试 ${errorCode}_error (应该产生 warning/error):`);
  result.mbtMdTest = runMoonTest(errorExamplePath, errorCode);

  if (result.mbtMdTest.hasExpected) {
    console.log(`✅ ${errorCode}_error 产生了预期的 warning/error`);
  } else {
    console.log(`❌  ${errorCode}_error 没有产生预期的 warning/error 或产生了预期外的 warning/error`);
  }

  // 测试 xxxx_fixed - 不应该有任何 warning 或 error
  console.log(`🧪 测试 ${errorCode}_fixed (不应该有任何 warning/error):`);
  result.suggestionTest = runMoonTest(fixExamplePath);

  if (result.suggestionTest.hasExpected) {
    console.log(`✅ ${errorCode}_fixed 没有 warning/error`);
  } else {
    console.log(`❌ ${errorCode}_fixed 有 warning/error，但不应该有`);
  }

  // 判断整体结果
  if (result.mbtMdTest && result.suggestionTest) {
    if (result.mbtMdTest.hasExpected && result.suggestionTest.hasExpected) {
      result.overall = 'pass';
      console.log(`✅ ${errorCode} 检查通过！`);
    } else {
      result.overall = 'fail';
      console.log(`❌ ${errorCode} 检查失败`);
    }
  } else {
    result.overall = 'error';
    console.log(`❌ ${errorCode} 检查出错`);
  }

  return result;
}

/**
 * 获取所有 error code 列表
 * @returns {string[]} - error code 列表
 */
function getAllErrorCodes() {
  if (!fs.existsSync(ERROR_CODES_DIR)) {
    console.error(`❌ 错误：目录 ${ERROR_CODES_DIR} 不存在`);
    return [];
  }

  const files = fs.readdirSync(ERROR_CODES_DIR);
  const errorCodes = files
    .filter(file => /^E\d{4}\.md$/.test(file))
    .map(file => {
      const match = /^E(\d{4})\.md$/.exec(file);
      return match ? match[1] : null;
    })
    .filter(code => code !== null)
    .sort();

  return errorCodes;
}

/**
 * 主函数
 */
function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('📋 用法: node check_error_docs.js [error_code|all]');
    console.log('示例:');
    console.log('  node check_error_docs.js 0001    # 检查特定错误代码');
    console.log('  node check_error_docs.js all      # 检查所有错误代码');
    return;
  }

  const target = args[0];

  if (target === 'all') {
    console.log('🔍 检查所有错误代码...');
    const errorCodes = getAllErrorCodes();

    if (errorCodes.length === 0) {
      console.log('❌ 没有找到任何 .mbt 文件');
      return;
    }

    console.log(`📝 找到 ${errorCodes.length} 个错误代码: ${errorCodes.join(', ')}`);

    const results = [];
    let passCount = 0;
    let failCount = 0;

    for (const errorCode of errorCodes) {
      const result = checkErrorCode(errorCode);
      results.push(result);

      if (result.overall === 'pass') {
        passCount++;
      } else {
        failCount++;
      }
    }

    // 输出总结
    console.log('='.repeat(60));
    console.log('📊 检查总结:');
    console.log(`✅ 通过: ${passCount}`);
    console.log(`❌ 失败: ${failCount}`);
    console.log(`📈 总计: ${results.length}`);

    if (failCount > 0) {
      console.log('❌ 失败的错误代码:');
      results
        .filter(r => r.overall !== 'pass')
        .forEach(r => {
          console.log(`  - ${r.errorCode}: ${r.overall}`);
        });
    }

    // 如果有失败的，返回非零退出码
    process.exit(failCount > 0 ? 1 : 0);

  } else {
    // 检查单个错误代码
    const errorCode = target.toUpperCase();
    if (!/^\d+$/.test(errorCode)) {
      console.error('❌ 错误：错误代码格式不正确，应该类似 0001');
      process.exit(1);
    }

    const result = checkErrorCode(errorCode);

    // 输出详细信息
    if (result.mbtMdTest) {
      console.log(`📋 ${errorCode}_error 测试输出:`);
      console.log('--- stdout ---');
      console.log(result.mbtMdTest.output);
      if (result.mbtMdTest.error) {
        console.log('--- stderr ---');
        console.log(result.mbtMdTest.error);
      }
    }

    if (result.suggestionTest) {
      console.log(`📋 ${errorCode}_fixed 测试输出:`);
      console.log('--- stdout ---');
      console.log(result.suggestionTest.output);
      if (result.suggestionTest.error) {
        console.log('--- stderr ---');
        console.log(result.suggestionTest.error);
      }
    }

    process.exit(result.overall === 'pass' ? 0 : 1);
  }
}

// 当直接运行此脚本时执行 main 函数
if (require.main === module) {
  main();
}

module.exports = { checkErrorCode, getAllErrorCodes, runMoonTest: runMoonTest };