import { expect, test, type Page } from "@playwright/test";

async function edit(page: Page, code: string) {
  await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
  await page.evaluate((code) => navigator.clipboard.writeText(code), code);
  await page.locator(".monaco-editor textarea").focus();
  await page.keyboard.press("ControlOrMeta+A");
  await page.keyboard.press("ControlOrMeta+V");
}

test("Tour runs its bundled compiler and clears obsolete output and diagnostics", async ({
  page,
}) => {
  const errors: string[] = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto("/");
  await expect(page.locator("#output")).toHaveText("hello");
  await expect(page.locator(".moonbit-trace")).toContainText(["a = hello"]);

  await edit(page, 'fn main { let answer : Int = "wrong"; println(answer) }');
  await expect(page.locator(".squiggly-error").first()).toBeVisible();
  await expect(page.locator("#output")).toContainText("Int");
  await expect(page.locator("#output")).not.toContainText("hello");

  await edit(page, "fn main { let answer = 42; println(answer) }");
  await expect(page.locator("#output")).toHaveText("42");
  await expect(page.locator(".squiggly-error")).toHaveCount(0);
  await expect(page.locator(".moonbit-trace")).toContainText(["answer = 42"]);
  expect(errors).toEqual([]);
});

test("changing lessons replaces edited code and its execution results", async ({
  page,
}) => {
  await page.goto("/");
  await expect(page.locator("#output")).toHaveText("hello");
  await edit(page, 'fn main { println("previous lesson") }');
  await expect(page.locator("#output")).toHaveText("previous lesson");
  await page.locator("#nav-next a").click();
  await expect(page).toHaveURL(/\/basics\/variable\/index\.html$/);
  await expect(page.locator("#output")).toHaveText("10\n30\n11\n20\n100\n3.14");
  await expect(page.locator(".moonbit-trace")).toContainText(["a = 10"]);
  await expect(page.locator(".squiggly-error")).toHaveCount(0);
});
