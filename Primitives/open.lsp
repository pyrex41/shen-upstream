"Copyright (c) 2010-2021, Mark Tarver

   3 clause BSD; see license"
   
(SETQ *absolute* NIL)   

(DEFUN open (String Direction) 
  (LET ((Path (IF (MEMBER String *absolute* :TEST 'STRING-EQUAL) 
                  String 
                  (FORMAT NIL "~A~A" *home-directory* String)))) 
       (cl.openh Path Direction)))             

(DEFUN cl.openh (Path Direction) 
      (COND ((EQ Direction 'in) 
             (OPEN Path :DIRECTION :INPUT 
                        :ELEMENT-TYPE '(UNSIGNED-BYTE 8))) 
            ((EQ Direction 'out) 
             (OPEN Path :DIRECTION :OUTPUT 
                        :ELEMENT-TYPE '(UNSIGNED-BYTE 8)
                        :IF-EXISTS :SUPERSEDE)) 
            (T (ERROR "invalid direction"))))