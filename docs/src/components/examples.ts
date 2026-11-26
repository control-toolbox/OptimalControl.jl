// The examples of the gallery, in reading order: one source for the cards of the gallery
// (ExamplesGallery.vue) and for the line of facts under the title of each example
// (ExampleFacts.vue). `id` is the file name of the page in `examples/`, and the name of its
// thumbnail, saved by the page at build time in `public/gallery/<id>.svg` (see
// `gallery_thumbnail` in docs/make.jl).

export interface Example {
  id: string
  title: string
  story: string
  introduces: string
  facts: string[]
}

export const examples: Example[] = [
  {
    id: 'double-integrator-energy',
    title: 'Energy minimisation',
    story: 'A wagon on a rail, transferred with the least energy.',
    introduces: '@def, solve, plot, a Hamiltonian flow, shooting from the direct solution',
    facts: ['2 states', '1 control', 'fixed final time', 'Lagrange cost', 'smooth control'],
  },
  {
    id: 'double-integrator-time',
    title: 'Time minimisation (bang–bang)',
    story: 'The same wagon, with a bounded force, transferred as fast as possible.',
    introduces: 'a free final time, the switching time read off the direct solution, concatenation of flows',
    facts: ['2 states', '1 control', 'free final time', 'Mayer cost', 'bang–bang'],
  },
  {
    id: 'control-free',
    title: 'Parameter estimation without a control',
    story: 'A growth rate fitted to data, and the pulsation of an oscillator, with no control.',
    introduces: 'problems without a control, the costate of the variable',
    facts: ['1 or 2 states', 'control-free', '1 parameter', 'data fitting'],
  },
  {
    id: 'control-and-variable',
    title: 'Control and variable together',
    story: 'The same two systems, with a control.',
    introduces: 'a parameter and a control optimised together, two extremals compared',
    facts: ['1 or 2 states', '1 control', '1 parameter', 'Bolza cost'],
  },
  {
    id: 'turnpike',
    title: 'Turnpike (bang–singular–bang)',
    story: 'A scalar system whose optimal control is bang, singular, then bang.',
    introduces: 'singular arcs, switching times as shooting unknowns, three flows concatenated',
    facts: ['1 state', '1 control', 'fixed final time', 'Lagrange cost', 'singular arc'],
  },
  {
    id: 'singular-control',
    title: 'Singular control',
    story: 'A vehicle in a drift field, in minimum time.',
    introduces: 'the singular control by hand and with Lift and @Lie',
    facts: ['3 states', '1 control', 'free final time', 'Mayer cost', 'singular arc', 'Lie brackets'],
  },
  {
    id: 'state-constraint',
    title: 'State constraint',
    story: 'The wagon with a speed limit, then with a bound on its position (Bryson–Denham).',
    introduces: 'boundary arcs, multipliers=, touch points and costate jumps',
    facts: ['2 states', '1 control', 'fixed final time', 'Lagrange cost', 'state constraint'],
  },
  {
    id: 'logo',
    title: 'The logo',
    story: 'A low-thrust orbit transfer, drawn three times.',
    introduces: 'an initial guess from an analytical trajectory, plotting with Makie',
    facts: ['4 states', '2 controls', 'fixed final time', 'Lagrange cost', 'Makie'],
  },
]
