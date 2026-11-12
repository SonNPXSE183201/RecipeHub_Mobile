import { describe, expect, it } from 'vitest';
import { adjacentPage, bookEntries, completeBook, searchBook, bookPageCount, swipePageDelta, pageTurnDuration } from '@/lib/ebooklet';
import { recipes, sops } from '@/lib/recipe-data';

describe('Complete recipe and SOP handbook', () => {
 it('includes a closing page after all documents', () => { expect(bookPageCount).toBe(recipes.length + sops.length + 1); });
 it('turns only sufficiently horizontal swipes', () => { expect(swipePageDelta(-72, 0)).toBe(1); expect(swipePageDelta(72, 0)).toBe(-1); expect(swipePageDelta(-71, 0)).toBe(0); expect(swipePageDelta(-80, 100)).toBe(0); });
 it('starts with a 400ms page turn within the requested 350–450ms range', () => { expect(pageTurnDuration).toBe(.4); });
 it('includes full instructions for every SOP, not only its title', () => {
  for (const sop of sops) expect(bookEntries.find(e => e.kind === 'sop' && e.name === sop.name)?.steps).toEqual(sop.steps);
  expect(bookEntries.length).toBe(recipes.length + sops.length);
 });
 it('finds both recipe and SOP names and retains exact destination indexes', () => {
  expect(searchBook('caramel')[0]?.entry.kind).toBe('recipe');
  const result = searchBook('ve sinh may')[0];
  expect(result?.entry.kind).toBe('sop');
  expect(bookEntries[result?.index ?? -1]?.name).toBe('Vệ sinh máy espresso');
 });
 it('refuses a full export when a SOP is missing', () => {
  expect(completeBook(bookEntries.filter(e => e.name !== sops[0]?.name))).toBe(false);
  expect(completeBook(bookEntries)).toBe(true);
 });
 it('refuses a full export when SOP instructions are incomplete', () => {
  expect(completeBook(bookEntries.map(e => e.kind === 'sop' ? { ...e, steps: [] } : e))).toBe(false);
 });
 it('keeps previous and next navigation within actual document bounds', () => {
  expect(adjacentPage(0, -1)).toBe(0);
  expect(adjacentPage(bookEntries.length - 1, 1)).toBe(bookEntries.length - 1);
  expect(adjacentPage(recipes.length, 1)).toBe(recipes.length + 1);
 });
});