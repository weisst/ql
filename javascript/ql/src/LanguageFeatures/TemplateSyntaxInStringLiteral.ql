/**
 * @name Template syntax in string literal
 * @description A string literal appears to use template syntax but is not quoted with backticks.
 * @kind problem
 * @problem.severity warning
 * @id js/template-syntax-in-string-literal
 * @precision high
 * @tags correctness
 */
 
import javascript

/** A toplevel that contains at least one template literal. */
class CandidateTopLevel extends TopLevel {
  CandidateTopLevel() {
    exists (TemplateLiteral template | template.getTopLevel() = this)
  }
}

/** A string literal in a toplevel that contains at least one template literal. */
class CandidateStringLiteral extends StringLiteral {
  CandidateTopLevel tl;
  string v;

  CandidateStringLiteral() {
    tl = this.getTopLevel() and
    v = getStringValue()
  }

  /**
   * Extracts a `${...}` part from this string literal using an inexact regular expression.
   *
   * Breakdown of the sequence matched by the expression:
   * - any prefix and then `${`
   * - any amount of whitespace and simple unary operators
   * - name of the variable
   * - optionally: a character terminating the identifier token, followed by anything
   * - `}`, followed by anything
   */
  string getAReferencedVariable() {
    result = v.regexpCapture(".*\\$\\{[\\s+\\-!]*([\\w\\p{L}$]+)([^\\w\\p{L}$].*)?\\}.*", 1)
  }

  /**
   * Gets an ancestor node of this string literal in the AST that can be reached without
   * stepping over scope elements.
   */
  ASTNode getIntermediate() {
    result = this or
    exists (ASTNode mid | mid = getIntermediate() |
      not mid instanceof ScopeElement and
      result = mid.getParent()
    )
  }

  /**
   * Holds if this string literal is in the given `scope`.
   */
  predicate isInScope(Scope scope) {
    scope instanceof GlobalScope or
    getIntermediate().(ScopeElement).getScope() = scope.getAnInnerScope*()
  }
}


/**
 * Holds if `obj` has a property for each template variable in `lit` and they occur as arguments
 * to the same call.
 *
 * This recognises a typical pattern in which template arguments are passed along with a string,
 * for example:
 *
 * ```
 *   output.emit('<a href="${url}">${name}$</a>',
 *        { url: url, name: name } );
 * ```
 */
predicate providesTemplateVariablesFor(ObjectExpr obj, CandidateStringLiteral lit) {
  exists (CallExpr call | call.getAnArgument() = obj and call.getAnArgument() = lit) and
  forex (string name | lit.getAReferencedVariable() = name | hasProperty(obj, name))
}

/** Holds if `object` has a property with the given `name`. */
predicate hasProperty(ObjectExpr object, string name) {
  name = object.getAProperty().getName()
}

/**
 * Gets a declaration of variable `v` in `tl`, where `v` has the given `name` and
 * belongs to `scope`.
 */
VarDecl getDeclIn(Variable v, Scope s, string name, CandidateTopLevel tl) {
  v.getName() = name and
  v.getADeclaration() = result and
  v.getScope() = s and
  result.getTopLevel() = tl
}

from CandidateStringLiteral lit, Variable v, Scope s, string name, VarDecl decl
where decl = getDeclIn(v, s, name, lit.getTopLevel())
  and lit.getAReferencedVariable() = name
  and lit.isInScope(s)
  and not exists (ObjectExpr obj | providesTemplateVariablesFor(obj, lit))
  and not lit.getStringValue() = "${" + name + "}"
select lit, "This string is not a template literal, but appears to reference the variable $@.", 
    decl, v.getName()
