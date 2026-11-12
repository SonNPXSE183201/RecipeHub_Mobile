import { describe, expect, it } from 'vitest';
import { initialTimer, startTimer, pauseTimer, finishTimer, elapsedAt, firstMissing, validation, SubmissionGate, canReview } from '@/lib/prototype-state';
describe('Interrupted practice',()=>{
 it('uses elapsed real time after background or lock',()=>{const t=startTimer(initialTimer,1000);expect(elapsedAt(t,61000)).toBe(60000);});
 it('does not count paused time',()=>{const paused=pauseTimer(startTimer(initialTimer,1000),11000);expect(elapsedAt(paused,41000)).toBe(10000);});
 it('resumes without losing the earlier elapsed time',()=>{const t=startTimer(pauseTimer(startTimer(initialTimer,1000),11000),31000);expect(elapsedAt(t,41000)).toBe(20000);});
 it('finish stops counting without saving a result',()=>{const t=finishTimer(startTimer(initialTimer,1000),6000);expect(t.phase).toBe('finished');expect(elapsedAt(t,20000)).toBe(5000);expect('saved' in t).toBe(false);});
});
describe('Submission and roles',()=>{
 it('locates the first unanswered question',()=>{expect(firstMissing([1,null,0])).toBe(1);});
 it('requires a subject and nonempty description',()=>{expect(validation('',' ').subject).not.toBe('');expect(validation('Latte',' ').text).not.toBe('');expect(validation('Latte','note')).toEqual({subject:'',text:''});});
 it('prevents concurrent double submissions',async()=>{const gate=new SubmissionGate();let count=0;let resolve:()=>void=()=>{};const wait=new Promise<void>(r=>{resolve=r;});const first=gate.run(async()=>{count++;await wait;});expect(await gate.run(async()=>{count++;})).toBe(false);resolve();await first;expect(count).toBe(1);});
 it('permits retry after failure',async()=>{const gate=new SubmissionGate();await expect(gate.run(async()=>{throw Error('offline');})).rejects.toThrow('offline');expect(await gate.run(async()=>{})).toBe(true);});
 it('restricts review actions to the manager preview role',()=>{expect(canReview('barista')).toBe(false);expect(canReview('manager')).toBe(true);});
});
