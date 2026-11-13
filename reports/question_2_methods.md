# Question 2: finalized empirical method

## Scope

Estimate the observed frequency of DO at or below 5 mg/L at all three sites,
and at exactly one of the three sites. Analyze CTD top, CTD bottom, Winkler top
and Winkler bottom separately, pooling all seasons and years in the snapshot.
These estimates describe sampled, complete same-day occasions; they are not
continuous-time probabilities or model-based predictions.

## Matching and calculation

1. Use the cleaned long data: negative DO measurements have been excluded;
   recorded zeros are retained. Missing DO remains available for missingness counts.
2. Group by date, measurement type and sampling location. Sort by sampling time
   and number observations within each group, starting at one.
3. Match the first readings across NC1-NC3, then the second readings, and so on,
   using date, measurement type and sampling-round number as the event identifier.
4. Keep only events with nonmissing DO at all three sites. No time-window filter
   is used. Missing times are not explicitly excluded; they sort after known times.
5. For each measurement type, count events where all three values are <= 5,
   and events where exactly one value is <= 5. Divide each count by the number
   of complete matched events for that measurement type.

The denominator is the same for the two probabilities within a measurement type.
Multiple sampling rounds on one date each contribute an event. No assumption of
independence between sites is needed to count these joint outcomes directly.
Inference or confidence intervals would require additional sampling assumptions.

## Empirical results

| Measurement | Complete events | All three fail, count | All three fail | Exactly one fails, count | Exactly one fails |
|---|---:|---:|---:|---:|---:|
| CTD bottom | 506 | 289 | 57.11% | 44 | 8.70% |
| CTD top | 508 | 170 | 33.46% | 67 | 13.19% |
| Winkler bottom | 562 | 211 | 37.54% | 77 | 13.70% |
| Winkler top | 570 | 185 | 32.46% | 69 | 12.11% |

## Time-window sensitivity check

A separate analysis retained the same date/order triplets only when all three
sampling times were known and the earliest-to-latest span was at most 30 minutes.
The active analysis was not modified by this check.

| Measurement | Retained events | All three fail | Exactly one fails |
|---|---:|---:|---:|
| CTD bottom | 483 | 56.73% | 8.70% |
| CTD top | 485 | 33.61% | 12.58% |
| Winkler bottom | 529 | 36.67% | 13.80% |
| Winkler top | 535 | 31.96% | 12.15% |

The filter removes 4.5-6.1% of complete events. The largest absolute probability
changes are 0.87 percentage points for all-three failure and 0.61 percentage
points for exactly-one failure. These changes are small in this snapshot; they
do not establish equivalence or validate exact simultaneity. Exploratory Fisher
comparisons of retained versus excluded events yielded no p-value below 0.05
(minimum 0.097), but do not account for temporal dependence and are not a formal
equivalence analysis. The empirical differences are the main sensitivity evidence.

## Interpretation and limitations

Same-day/order matching is retained by user decision for a transparent empirical
answer to question 2. Sampling times may differ by hours, and missing times or
unequal numbers of visits can make pairing uncertain. Describe the events as
same-day matched observations used as an approximation to simultaneous conditions.
The time-filter check supports numerical robustness of these estimates; it does
not remove the timing limitation. Complete-case estimates can also be affected
by which sampling events have missing DO.

The user finalized the joint probabilities on November 12, 2026, with no time
filter planned. Current outputs are `outputs/tables/joint_probabilities.csv`
and its LaTeX counterpart, plus `matched_observations_date_order.csv`.
The estimates and matching method are unchanged; the provisional label has
been removed. The timing limitation remains in the table caption and should
be stated when presenting results. Previous alternative matching outputs remain
reference-only under `outputs/tables/archive/`.

Suggested presentation disclaimer: "Joint probabilities use same-day/order
matched observations across NC1-NC3. Sampling times may differ, so these
observations approximate simultaneous conditions; no time-window filter was
applied."
