/**
 * @name Duplicate function
 * @description There is another function that shares a lot of code with this function.
 *              Extract the common parts to a shared utility function to improve maintainability.
 * @kind problem
 * @problem.severity recommendation
 * @id js/duplicate-function
 * @tags testability
 *       useless-code
 *       maintainability
 *       statistical
 *       non-attributable
 *       duplicate-code
 * @precision medium
 */

import javascript
import CodeDuplication
import semmle.javascript.RestrictedLocations

from Function f, Function g, float percent
where duplicateContainers(f, g, percent) and
      f.getNumBodyStmt() > 5 and
      not duplicateContainers(f.getEnclosingStmt().getContainer(), g.getEnclosingStmt().getContainer(), _)
select (FirstLineOf)f, percent.floor() + "% of statements in " + f.describe() +
       " are duplicated in $@.", (FirstLineOf)g, g.describe()
