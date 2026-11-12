export type NetworkMode = 'online' | 'weak' | 'offline';
export type TimerState = { phase: 'ready' | 'running' | 'paused' | 'finished'; elapsed: number; startedAt: number | null };
export const initialTimer: TimerState = { phase: 'ready', elapsed: 0, startedAt: null };
export function elapsedAt(timer: TimerState, now: number) { return timer.elapsed + (timer.phase === 'running' && timer.startedAt !== null ? Math.max(0, now - timer.startedAt) : 0); }
export function startTimer(timer: TimerState, now: number): TimerState { return timer.phase === 'ready' || timer.phase === 'paused' ? { ...timer, phase: 'running', startedAt: now } : timer; }
export function pauseTimer(timer: TimerState, now: number): TimerState { return timer.phase === 'running' ? { phase: 'paused', elapsed: elapsedAt(timer, now), startedAt: null } : timer; }
export function finishTimer(timer: TimerState, now: number): TimerState { return { phase: 'finished', elapsed: elapsedAt(timer, now), startedAt: null }; }
export const firstMissing = (answers: (number | null)[]) => answers.findIndex(answer => answer === null);
export const formatTime = (milliseconds: number) => { const s = Math.floor(milliseconds / 1000); return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`; };
export const canReview = (role: 'barista' | 'manager') => role === 'manager';
export function validation(subject: string, text: string) { return { subject: subject ? '' : 'Chọn công thức hoặc SOP cần phản hồi.', text: text.trim() ? '' : 'Mô tả vấn đề để quản lý biết cần kiểm tra điều gì.' }; }
export class SubmissionGate {
 private pending = false;
 async run(action: () => Promise<void>): Promise<boolean> { if (this.pending) return false; this.pending = true; try { await action(); return true; } finally { this.pending = false; } }
}
export const quizQuestions = [
 { text: 'Espresso được rót vào lúc nào khi pha Caramel Latte?', options: ['Trước khi thêm đá', 'Sau khi rót sữa', 'Cùng lúc với syrup'], answer: 1, explanation: 'Rót espresso sau sữa để tạo lớp và giữ hương vị.' },
 { text: 'Công thức minh họa dùng bao nhiêu syrup caramel?', options: ['10 ml', '20 ml', '40 ml'], answer: 1, explanation: 'Công thức minh họa dùng 20 ml syrup caramel.' },
 { text: 'Khi vừa mở một công thức, nhiệm vụ có tự hoàn thành không?', options: ['Có, chỉ cần mở', 'Không, cần xác nhận đã học'], answer: 1, explanation: 'Mở hoặc cuộn qua nội dung không đồng nghĩa với hoàn thành việc học.' },
];
