"Copyright (c) 2010-2021, Mark Tarver

   3 clause BSD; see license"

(DEFMACRO trap-error (X F) 
`(HANDLER-CASE ,X (ERROR (Condition) 
    (CLEAR-OUTPUT *ERROR-OUTPUT*)
    (FUNCALL ,F Condition))))
