Corpus

Simple system to aid in analyzing corpus of data, since this has
become a recurring problem.  The immediate application of this is
applying text clustering and machine learning techniques to the
UniLang log files.


Corpus will serve as the automatic classification system for UniLang,
which is necessary to achieving the desired capability of automatic
message routing.  The concept of Adjustable Autonomy is relevant here.

Corpus now has a reasonable UI and is now successfully classifying
messages with a reasonable accuracy.  We are using the rainbow -
bayesian text classifier.  This has suprisingly and astonishingly good
results considering how little information would appear to be present
in the sentences.  However, it is not sufficient.  While it usually
chooses the correct category, the error rate is still too high, and to
disambiguate some of the weaker classes will require extra
information.  Therefore, I am looking to incorporate other sources of
classification evidence, based on features recognized by other
external codebases.

Other features that will be added are as follows. Have the ability to
vet the automatic classifications.  A type system will be
created. Recipient agents can reject messages which will help with
classification.  Incorporate mass verification and classification
adjustment and subsequent message reclassification.

The next paragraph shows a very preliminary classification example,
and the current scheme (ranked in terms of probability associated with
example message).  Note that the classification is exactly correct.
The scheme system will be greatly revamped allowing a subsumption
hierarchy and will also focus more on what the actual routing commands
are.  So for instance, rather than "goal", we would have "(Agent:
Verber) (new-goal $1)" or rather than just
"icodebase-capability-request", have "(Agent: MyFRDCSA)
(capability-request Verber $1)".  I.E.  the responsible agent and the
corresponding command to be sent.

<pre>
(((Forgot to pick up pay check - need to go pick that ASAP.)))

                             observation	0.441955
                  verber-task-definition	0.244548
                       complex-statement	0.118441

  0) Finished
* 1) observation
* 2) verber-task-definition
  3) complex-statement
  4) icodebase-solution-to-extant-problem
  5) icodebase-capability-request
  6) event
  7) icodebase-input-data
  8) dream
  9) solution-to-extant-problem
  10) system-request
  11) policy
  12) priority-shift
  13) quote
  14) unclassifiable
  15) intersystem-relation
  16) SOP
  17) funny-annecdote
  18) unilang-client-outgoing-message
  19) goal
  20) icodebase-task
  21) suspicion
  22) not-a-unilang-client-entry
  23) dangling-clause
  24) capability-request
  25) rant
  26) icodebase-resource
  27) propaganda
  28) inspiring-annecdote
  29) shopping-list-item
>
</pre>

http://frdcsa.org/frdcsa/internal/corpus