/**
 * ═══════════════════════════════════════════════════════════════
 * TAROT DECK - 22 MAJOR ARCANA
 * ═══════════════════════════════════════════════════════════════
 * Complete tarot deck with relationship-focused meanings
 */

export const TAROT_CARDS = [
  {
    id: 0,
    code: "the_fool",
    name: "The Fool",
    coreMeaning: "New beginnings, taking risks, stepping into the unknown without a clear plan.",
    relationshipMeaning: "Jumping into connection quickly, following feelings without thinking it through, naive optimism about someone.",
    shadowMeaning: "Acting impulsively, repeating the same relationship mistakes, ignoring obvious red flags because it feels exciting."
  },
  {
    id: 1,
    code: "the_magician",
    name: "The Magician",
    coreMeaning: "Skill, resourcefulness, making things happen through focused action.",
    relationshipMeaning: "Knowing what you want and actively creating it, clear communication, having the tools to fix what's broken.",
    shadowMeaning: "Manipulation, using emotional tactics to control outcomes, saying what people want to hear without meaning it."
  },
  {
    id: 2,
    code: "the_high_priestess",
    name: "The High Priestess",
    coreMeaning: "Intuition, hidden knowledge, trusting what you sense beneath the surface.",
    relationshipMeaning: "Sensing something is off even when everything looks fine, trusting your gut about someone's real intentions.",
    shadowMeaning: "Overthinking every small sign, creating problems that don't exist, withdrawing instead of asking direct questions."
  },
  {
    id: 3,
    code: "the_empress",
    name: "The Empress",
    coreMeaning: "Nurturing, abundance, creating something meaningful through care and attention.",
    relationshipMeaning: "Deep emotional connection, making someone feel safe and valued, building something real together.",
    shadowMeaning: "Over-giving to people who don't reciprocate, losing yourself in taking care of others, expecting appreciation that never comes."
  },
  {
    id: 4,
    code: "the_emperor",
    name: "The Emperor",
    coreMeaning: "Structure, boundaries, taking control of your own life.",
    relationshipMeaning: "Setting clear expectations, knowing what you will and won't accept, creating stability through honesty.",
    shadowMeaning: "Being rigid and controlling, refusing to compromise, needing to dominate rather than collaborate."
  },
  {
    id: 5,
    code: "the_hierophant",
    name: "The Hierophant",
    coreMeaning: "Tradition, commitment, doing things the 'right' way according to external standards.",
    relationshipMeaning: "Following relationship scripts from family or culture, wanting official commitment, seeking validation from others.",
    shadowMeaning: "Staying in something because it looks right from the outside, ignoring your own needs to meet expectations, rigid thinking about how love should work."
  },
  {
    id: 6,
    code: "the_lovers",
    name: "The Lovers",
    coreMeaning: "Choice, alignment, deciding between two paths based on your values.",
    relationshipMeaning: "A significant choice between people or between staying and leaving, recognizing what actually matters to you.",
    shadowMeaning: "Avoiding the decision, staying stuck between options, wanting both safety and excitement without choosing."
  },
  {
    id: 7,
    code: "the_chariot",
    name: "The Chariot",
    coreMeaning: "Determination, moving forward despite internal conflict, forcing progress.",
    relationshipMeaning: "Pushing through doubt to make something work, refusing to give up even when it's hard, willpower over ease.",
    shadowMeaning: "Forcing something that doesn't fit, ignoring incompatibility through sheer effort, controlling rather than flowing."
  },
  {
    id: 8,
    code: "strength",
    name: "Strength",
    coreMeaning: "Inner resilience, compassion, handling difficulty with patience rather than force.",
    relationshipMeaning: "Staying gentle with someone's flaws, having the courage to be vulnerable, patience with a difficult situation.",
    shadowMeaning: "Tolerating mistreatment because you're 'strong enough to handle it', confusing patience with enabling, suppressing anger until it explodes."
  },
  {
    id: 9,
    code: "the_hermit",
    name: "The Hermit",
    coreMeaning: "Withdrawal, introspection, needing space to figure things out alone.",
    relationshipMeaning: "Taking a step back to understand what you really want, needing distance to see clearly, prioritizing yourself.",
    shadowMeaning: "Isolating to avoid dealing with problems, using 'space' as an excuse to ghost, refusing to communicate your needs."
  },
  {
    id: 10,
    code: "wheel_of_fortune",
    name: "Wheel of Fortune",
    coreMeaning: "Change, cycles, things shifting beyond your control.",
    relationshipMeaning: "Unexpected turns in how someone feels or acts, recognizing patterns that keep repeating, luck (good or bad) in timing.",
    shadowMeaning: "Blaming fate instead of taking responsibility, waiting for things to magically improve, refusing to break your own patterns."
  },
  {
    id: 11,
    code: "justice",
    name: "Justice",
    coreMeaning: "Fairness, consequences, getting what you've earned (good or bad).",
    relationshipMeaning: "Receiving honesty you've been waiting for, balance being restored, accountability for actions.",
    shadowMeaning: "Harsh judgment, holding grudges, punishing someone (or yourself) instead of understanding, cold logic without empathy."
  },
  {
    id: 12,
    code: "the_hanged_man",
    name: "The Hanged Man",
    coreMeaning: "Suspension, waiting, seeing things from a completely different angle.",
    relationshipMeaning: "Being in limbo, waiting for someone to decide, gaining new perspective by letting go of control.",
    shadowMeaning: "Staying stuck because moving feels too hard, martyring yourself, waiting passively when action is needed."
  },
  {
    id: 13,
    code: "death",
    name: "Death",
    coreMeaning: "Endings, transformation, letting go of what no longer serves you.",
    relationshipMeaning: "Recognizing something is truly over, accepting that a dynamic has fundamentally changed, necessary loss.",
    shadowMeaning: "Resisting inevitable endings, clinging to what's already dead, fear of moving forward into the unknown."
  },
  {
    id: 14,
    code: "temperance",
    name: "Temperance",
    coreMeaning: "Balance, patience, blending opposites into something harmonious.",
    relationshipMeaning: "Finding middle ground, mixing independence with intimacy, slow and steady progress rather than extremes.",
    shadowMeaning: "Over-compromising, losing yourself trying to keep the peace, avoiding conflict so much that nothing gets resolved."
  },
  {
    id: 15,
    code: "the_devil",
    name: "The Devil",
    coreMeaning: "Attachment, temptation, being trapped by your own desires or fears.",
    relationshipMeaning: "Staying because of physical chemistry or fear of being alone, toxic patterns that feel impossible to break, co-dependency.",
    shadowMeaning: "Blaming the other person for your own choices, playing victim while feeding the dysfunction, addiction to drama."
  },
  {
    id: 16,
    code: "the_tower",
    name: "The Tower",
    coreMeaning: "Sudden disruption, truth revealed, structures collapsing that were built on lies.",
    relationshipMeaning: "Discovering something that changes everything, a fight that brings buried issues to the surface, necessary destruction.",
    shadowMeaning: "Chaos for chaos's sake, destroying things out of anger rather than need, refusing to rebuild after the collapse."
  },
  {
    id: 17,
    code: "the_star",
    name: "The Star",
    coreMeaning: "Hope, healing, believing in better possibilities after difficulty.",
    relationshipMeaning: "Renewed faith after disappointment, seeing potential in someone again, allowing yourself to be vulnerable after being hurt.",
    shadowMeaning: "Naive hope disconnected from reality, ignoring present problems because 'it could get better', false optimism."
  },
  {
    id: 18,
    code: "the_moon",
    name: "The Moon",
    coreMeaning: "Confusion, illusion, not being able to see clearly what's real.",
    relationshipMeaning: "Uncertainty about someone's true feelings, projecting your hopes onto ambiguous situations, emotional fog.",
    shadowMeaning: "Creating drama from imagination, letting anxiety distort reality, choosing delusion over uncomfortable truth."
  },
  {
    id: 19,
    code: "the_sun",
    name: "The Sun",
    coreMeaning: "Clarity, joy, things finally feeling simple and right.",
    relationshipMeaning: "Easy connection without constant work, feeling seen and appreciated, genuine happiness without forcing it.",
    shadowMeaning: "Ignoring problems because things feel good right now, superficial happiness that avoids depth, arrogance."
  },
  {
    id: 20,
    code: "judgement",
    name: "Judgement",
    coreMeaning: "Reckoning, seeing yourself clearly, being called to account for your choices.",
    relationshipMeaning: "Facing the truth about your patterns, recognizing your role in what keeps happening, awakening to what you've been avoiding.",
    shadowMeaning: "Harsh self-criticism, judging yourself or others without compassion, refusing to accept growth or change."
  },
  {
    id: 21,
    code: "the_world",
    name: "The World",
    coreMeaning: "Completion, integration, arriving at a natural ending or fulfillment.",
    relationshipMeaning: "Full-circle moment, achieving what you wanted, feeling complete (with or without someone), closure.",
    shadowMeaning: "Refusing to let something end even when it's done, clinging to completion instead of starting fresh, stagnation."
  }
];

/**
 * Get a card by its ID
 * @param {number} id - Card ID (0-21)
 * @returns {object|null} Card object or null if not found
 */
export function getCardById(id) {
  return TAROT_CARDS.find((c) => c.id === id) || null;
}

/**
 * Get multiple cards by their IDs
 * @param {number[]} ids - Array of card IDs
 * @returns {object[]} Array of card objects (excluding nulls)
 */
export function getCardsByIds(ids) {
  return ids
    .map((id) => getCardById(id))
    .filter((card) => card !== null);
}

/**
 * Get random cards from the deck
 * @param {number} count - Number of cards to draw
 * @returns {object[]} Array of random card objects
 */
export function drawRandomCards(count = 3) {
  const shuffled = [...TAROT_CARDS].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, count);
}
