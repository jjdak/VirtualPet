import json

from context_world import ContextWorld
from server import ROOT, Runtime, main


class ContextRuntime(Runtime):
    world_type = ContextWorld

    def command(self, body):
        if isinstance(body, dict) and body.get('action') == 'example':
            example = ROOT/'docs/sim/living-world/w2/review/step700-example.json'
            body = {'action':'import', 'world':json.loads(example.read_text())}
        return super().command(body)

    def apply_environment(self, body):
        if body.get('weather') != self.world.weather:
            raise ValueError('天气已经变化。请核对当前天气后再应用。')
        super().apply_environment(body)

    def additional_command(self, body):
        if body.get('action') == 'weather':
            self.world.set_mode(body.get('mode'))
        else:
            super().additional_command(body)


if __name__ == '__main__':
    main(ContextRuntime, port=4194, saves=ROOT/'.runtime/living-world-w2', stage='W2')
