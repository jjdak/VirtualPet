from copy import deepcopy
from pathlib import Path
import sys
import tempfile
import unittest

SRC = Path(__file__).resolve().parents[1]/'src'
sys.path.insert(0, str(SRC))
from context_server import ContextRuntime
from context_world import ContextWorld
from world import FOODS, HOMES, World


class ContextTests(unittest.TestCase):
    def test_meal_uses_weather_at_contact(self):
        w = ContextWorld()
        r = w.residents['A']
        w.tick = 79
        r.phase, r.target, r.pos = 'outbound', 'p', list(FOODS['p'])
        w.step()
        self.assertEqual((w.weather, w.tick), ('rain',80))
        self.assertEqual((r.brain.values['p'],r.brain.counts['p']),(-1,1))
        self.assertEqual(r.history[-1]['weather'],'rain')
        w.change_weather('sun')
        self.assertEqual(r.brain.counts['p'],0)

    def test_weather_switch_alone_adds_no_values_and_effect_edits_are_local(self):
        w = ContextWorld()
        w.set_mode('rain')
        w.intervene('q',-1,False)
        w.hint('A','q')
        for person in w.residents.values():
            self.assertEqual(sum(person.brain.counts.values()),0)
        self.assertEqual(w.residents['B'].hints,[])
        w.set_mode('sun')
        self.assertFalse(w.resources['q']['available'])
        self.assertEqual(w.resources['p']['effect'],1)
        w.intervene('q',1,True)
        w.set_mode('rain')
        self.assertEqual(w.resources['q'],dict(effect=-1,available=True))

    def test_reports_only_validated_against_matching_weather_experience(self):
        w = ContextWorld()
        a,b = w.residents.values()
        a.pos, a.target = list(FOODS['p']), 'p'
        w.consume(a)
        a.pos = list(HOMES['A'])
        w.share()
        self.assertEqual(b.brain.inbox['p']['claim'],1)
        w.set_mode('rain')
        self.assertFalse(b.brain.inbox)
        b.pos,b.target = list(FOODS['p']),'p'
        w.consume(b)
        self.assertEqual(b.brain.validation_count,0)
        w.set_mode('sun')
        self.assertEqual(b.brain.counts['p'],0)
        w.consume(b)
        self.assertEqual((b.brain.validation_count,b.brain.matches),(1,1))

    def test_changes_to_unvisited_quality_hidden_from_choice(self):
        w = ContextWorld()
        other = ContextWorld.restore(w.snapshot())
        other.intervene('p',-1,True)
        for _ in range(3):
            w.step()
            other.step()
        self.assertEqual(w.residents['A'].snapshot(),other.residents['A'].snapshot())

    def test_saved_journey_and_schedule_continue_identically(self):
        w = ContextWorld(17)
        for _ in range(154):
            w.step()
        w.hint('B','q')
        other = ContextWorld.restore(w.snapshot())
        for i in range(180):
            for world in (w,other):
                if i==40:
                    world.set_mode('sun')
                if i==60:
                    world.set_mode('auto')
                world.step()
            self.assertEqual(w.snapshot(),other.snapshot())

    def test_bad_import_and_stale_intervention_preserve_state(self):
        with tempfile.TemporaryDirectory() as directory:
            rt = ContextRuntime(directory)
            rt.command({'action':'weather','mode':'rain'})
            before = rt.world.snapshot()
            bad = deepcopy(before)
            bad['reserve']['A']['brain']['values']['p'] = 999
            for data in (bad,World().snapshot(),{**before,'change_at':1}):
                with self.assertRaises(ValueError):
                    rt.command({'action':'import','world':data})
                self.assertEqual(rt.world.snapshot(),before)
            with self.assertRaises(ValueError):
                rt.command(dict(action='environment',kind='p',effect=1,available=True,weather='sun'))
            self.assertEqual(rt.world.snapshot(),before)
            self.assertEqual(ContextRuntime(directory).world.snapshot(),before)
