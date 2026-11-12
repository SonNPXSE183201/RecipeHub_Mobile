import { recipes, sops, normalize, type Recipe } from './recipe-data';

export type BookEntry = { kind: 'recipe' | 'sop'; name: string; group: string; steps: string[]; time: string; recipe?: Recipe };
export const bookEntries: BookEntry[] = [
 ...recipes.map(recipe => ({ kind: 'recipe' as const, name: recipe.name, group: recipe.category, steps: recipe.steps, time: recipe.time, recipe })),
 ...sops.map(sop => ({ ...sop, kind: 'sop' as const, group: 'Quy trình SOP' })),
];
export const bookGroups = [...new Set(bookEntries.map(entry => entry.group))];
export const bookPageCount = bookEntries.length + 1;
export const pageTurnDuration = 0.4;
export function swipePageDelta(dx: number, dy: number) { return Math.abs(dx) >= 72 && Math.abs(dx) > Math.abs(dy) * 1.8 ? (dx < 0 ? 1 : -1) : 0; }
export function searchBook(query: string) { return bookEntries.map((entry, index) => ({ entry, index })).filter(({ entry }) => normalize(entry.name).includes(normalize(query.trim()))); }
export function adjacentPage(page: number, delta: number, total = bookEntries.length) { return Math.max(0, Math.min(total - 1, page + delta)); }
export function completeBook(entries: BookEntry[]) {
 return entries.length === bookEntries.length && bookEntries.every(expected => entries.some(entry => entry.kind === expected.kind && entry.name === expected.name && entry.steps.length === expected.steps.length && entry.steps.every((step, index) => step === expected.steps[index])));
}
export type ReadingPosition = { page: number; started: boolean; scrolls: Record<number, number>; block?: number; offset?: number };
export const initialReadingPosition: ReadingPosition = { page: 0, started: false, scrolls: {} };