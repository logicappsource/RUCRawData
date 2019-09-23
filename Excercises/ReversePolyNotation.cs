using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;


namespace ReversePolish
{
    class Program
    {

        static void Main(string[] args)
        {
            Stack<int> stackValues = new Stack<int>();

            string inputValue;
            Console.Write("Enter values to calc reverse Polish notation: ");
            inputValue = Console.ReadLine();

            foreach (string token in args)
            {
                int value;
                if (int.TryParse(token, out value))
                {
                    // push to stack if numberic value
                    stackValues.Push(value);
                }
                else
                {
                    // evaluate the expression
                    int rhs = stackValues.Pop();
                    int lhs = stackValues.Pop();

                    switch (token)
                    {
                        case "+":
                            stackValues.Push(lhs + rhs);
                            break;
                        case "-":
                            stackValues.Push(lhs - rhs);
                            break;
                        case "*":
                            stackValues.Push(lhs * rhs);
                            break;
                        case "/":
                            stackValues.Push(lhs / rhs);
                            break;
                        case "%":
                            stackValues.Push(lhs % rhs);
                            break;
                        default:
                            throw new ArgumentException(string.Format("Unidentified token!: {0}", token));
                    }
                }
            }
            // last item is result
            Console.WriteLine("Result=", stackValues.Pop());
        }
    }
}
