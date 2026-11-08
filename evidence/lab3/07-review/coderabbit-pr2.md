# CodeRabbit – PR #2 (xuất qua GitHub API ngày 2026-11-08)

## #1 `android/app/src/main/kotlin/com/recipehub/mobile/MainActivity.kt:83`

** Minor** · **Functional Correctness** · **Quick win**

**Return the display name that Android actually saved, not the requested name.**

`SopBookPdf.fileName` uses only the date. `PracticeReportPdf.fileName` uses the minute. A second export inside that window inserts the same `DISPLAY_NAME` into the same `RELATIVE_PATH`. On Android 10 and later, MediaProvider renames the new row, for example to `so-tay-cong-thuc_20261108 (1).pdf`. This method returns only the URI. `AndroidFileSaveService.savePdf` then builds `displayPath` from the requested `fileName`. The "Đã lưu: …" snackbar therefore shows the name of the earlier file. "Mở" and "Chia sẻ" still work because they use the URI. A user who searches Tải xuống by name finds the wrong export. The fallback text "Vui lòng mở file từ Tải xuống" sends users to that search.

Fix: after the publish update, query `MediaStore.Downloads.DISPLAY_NAME` for `uri`. Return both values to Dart. Use the returned name for `SavedFile.name` and `displayPath`.

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533281

## #2 `lib/core/models/session_models.dart:82`

** Minor** · **Functional Correctness** · **Quick win**

**Make the `passwordNotApplicable` message accurate for guest users.**

`ChangePasswordPage` and `AuthViewModel.changePassword` return this code for any non-password account. That includes guests, who did not sign in with Google. A guest sees "Tài khoản đăng nhập bằng Google không dùng mật khẩu RecipeHub", which is wrong for them. The sentence also lacks a final period, unlike the other messages.

Use a neutral message. Then update the string asserted in `test/password_change_test.dart` (the Google/guest test).

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533282

## #3 `lib/core/services/firebase/firebase_notification_service.dart:36`

** Major** · **Data Integrity & Integration** · **Quick win**



**Keep the most recent pending notifications**

When 100 notifications accumulate before history is loaded, the handler drops every later notification from the pending queue. Those notifications can be missing from history unless they are opened separately. Keep the last 100 entries instead.

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533290

## #4 `lib/core/services/firebase/firestore_training_repository.dart:270`

** Major** · **Functional Correctness** · **Heavy lift**

**Attempt 1 never stores a score, so progress screens treat a submitted first quiz as not taken.**

For `attemptNo == 1`, `scoreBefore` is null. The write omits `score`, and the attempt is never updated, because the rules deny updates. `attemptFromDoc` then maps the missing value to `-1`, which makes `hasScore` false.

The consequences are:
- `TrainingViewModel.quizAverage` excludes every first attempt.
- `PersonalProgressPage` sets `hasQuiz = attempts.any((a) => a.hasScore)`. A user who submitted once sees "Chưa làm quiz", although the quiz page just showed the score.
- The quiz history row shows "Đã nộp" in place of the score.

This affects every user who has made exactly one attempt. One fix is to compute scores on the read path. After attempt 1 exists, the user can read the answer key. In `watchMyAttempts`, or in the view model, read `answerKey` for each quiz that has an unscored attempt, then fill in `score` with `_score(key, answers)`. A second fix is to write the graded result after the key read to a separate create-only document, such as `users/{uid}/quizResults/{attemptId}`, and add a matching rule.

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533293

## #5 `lib/core/viewmodels/auth_viewmodel.dart:316`

** Minor** · **Maintainability & Code Quality** · **Quick win**

**Stop reporting routine credential failures to Crashlytics.**

`_isUnexpected` excludes only `cancelled` and `network`. A mistyped password gives `invalidCredentials`, which now counts as unexpected. Every failed email sign-in then calls `_crash.recordError`. Rate-limit responses (`tooManyRequests`) and disabled accounts (`disabled`) do the same. The same applies to `sendPasswordReset` at lines 341-343. This floods Crashlytics with user-input errors and hides real faults.

Exclude the expected user-facing codes in `_isUnexpected`:

```diff
   static bool _isUnexpected(AuthFailure f) =>
-      f.code != AuthFailureCode.cancelled && f.code != AuthFailureCode.network;
+      f.code != AuthFailureCode.cancelled &&
+      f.code != AuthFailureCode.network &&
+      f.code != AuthFailureCode.invalidCredentials &&
+      f.code != AuthFailureCode.tooManyRequests &&
+      f.code != AuthFailureCode.disabled;
```

`_isUnexpected` is at lines 110-111, outside the changed range.

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533296

## #6 `lib/core/viewmodels/recipe_viewmodel.dart:78`

** Minor** · **Stability & Availability** · **Quick win**



**Reset the recipe subscription when it stops.**

If the Firestore listener fails after sign-out, a later sign-in loads recipes once but skips a new listener at the same limit. Real-time updates then stop.

Cancel the subscription on sign-out. Also clear the current subscription when it ends or fails, so a later load can subscribe again. Cancel it before clearing it on error, and prevent callbacks from an old subscription from clearing a replacement.

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533298

## #7 `lib/core/viewmodels/training_viewmodel.dart:191`

** Minor** · **Data Integrity & Integration** · **Quick win**

**Writes derive from the progress and attempts streams, but those streams have no ready or error state.**

The `watchProgress` and `watchMyAttempts` listeners set no `LoadState`, and their `_fail` callbacks pass `() {}`. Two write paths still use those values as inputs:

- `toggleSection` passes `completedSectionsOf(task.id)` as `current`. If the progress snapshot has not arrived or the stream failed, `current` is `[]`. `FirestoreTrainingRepository.setSectionDone` then calls `set()` without merge, which overwrites the stored `completedSections` with one index. The user's saved progress is lost.
- `submitQuiz` computes `next` from `attemptsOf(quiz.id)`. If the attempts stream is not loaded or failed, `next` is `1` again. The `set()` on the existing `quizAttempts/{uid}_{quiz}_1` document becomes an update, and the rules deny updates. The user sees the permission-denied message on every retry.

Track readiness for both streams. Reject or disable these actions until the matching stream has emitted.

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533301

## #8 `lib/core/viewmodels/training_viewmodel.dart:389`

** Minor** · **Functional Correctness** · **Quick win**

**`AdminTrainingViewModel` is never reset on sign-out, so a later Admin session stays in the error state.**

`start()` runs only once because of the `_started` guard. `AuthGate` clears `TrainingViewModel` on sign-out, but it does not clear this view model. After sign-out, the Firestore listeners fail with permission errors, and `_fail` sets `_state = LoadState.error`. When an Admin signs in again, `_startAdminData()` calls `start()`, which returns immediately. The Admin screens then show the error state until the user taps "Thử lại". The previous Admin's `_staff`, `_evaluations` and `_progress` also stay in memory.

Add a `clear()` method that cancels the subscriptions, resets the data, and sets `_started = false`. Call it from `AuthGate` in the unauthenticated branch.

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533303

## #9 `lib/features/feedback/create_feedback_page.dart:250`

** Minor** · **Functional Correctness** · **Quick win**

**Feedback over 2000 characters fails with a misleading permission error.**

The Firestore `validNewFeedback` rule limits `content` to 2000 characters. The content `TextField` (Lines 597-626) has no `maxLength`, and `_submitFeedback` does not check the length. A longer entry makes `create` fail with `permission-denied`. `FirestoreFeedbackRepository._map` turns that into "Bạn không có quyền với phản hồi này." The user then has no hint that the text is too long.

Limit the input to 2000 characters. Alternatively, check the length before the upload and the `create` call. The `TextField` change is outside the selected lines. Apply it in `build`:

```dart
TextField(
  controller: _contentCtrl,
  maxLines: 6,
  maxLength: 2000,
  // ...existing decoration
)
```

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533307

## #10 `lib/features/lookup/recipe_detail_size_page.dart:566`

** Minor** · **Functional Correctness** · **Quick win**

**Format the video timestamp as `mm:ss`.**

The label hard-codes the `00:` prefix and pads only the total seconds. `RecipeMapper` now computes `videoStartSeconds` as the cumulative sum of real step durations. A step that starts at 75 seconds therefore shows `Mốc video: 00:75`. `StepVideoGuidePage._time` formats the same value correctly.

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533310

## #11 `lib/features/lookup/step_video_guide_page.dart:628`

** Major** · **Functional Correctness** · **Quick win**

**Remove the hard-coded equipment and completion criteria shown for every recipe.**

`_equipmentForStep` (lines 223-247) and `_completionCriteriaForStep` are switch statements on the step number. They hold text for one Cold Brew orange recipe, for example "Bình ủ lạnh Toddy" and "lát cam vàng sấy". The default branch applies to all other steps. This change replaces mock data with Firestore recipes. Every real recipe now shows this unrelated equipment and these unrelated acceptance criteria on the "DỤNG CỤ & TIÊU CHÍ HOÀN THÀNH BƯỚC" card. In an SOP training app, that content misleads staff.

`RecipeMapper` already adds the real `equipment` and `safetyNote` to `instruction`. Remove both helpers and the card. Alternatively, add real fields for them to `RecipeStepItem` and render the card only when they are present.

```dart
// Remove _equipmentForStep and _completionCriteriaForStep (lines 223-247)
// and the "3. Equipment & Completion Criteria Card" Container,
// or render it only when RecipeStepItem carries real equipment/criteria data.
```






Also applies to: 633-637

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533314

## #12 `lib/features/practice/practical_evaluation_page.dart:478`

** Minor** · **Data Integrity & Integration** · **Quick win**



**Match `_selectedRecipe` to the current recipe list.**

When a live update changes a recipe's name or version, the dropdown can show the new values while saving the old values. If the recipe leaves the list, the dropdown shows its hint but saving can still use the old recipe.

Link: https://github.com/SonNPXSE183201/RecipeHub_Mobile/pull/2#discussion_r4504533317
