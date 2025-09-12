import re


class Sumarizer:
    system_prompt = """<Inputs>
{PYTHON_FILE_CONTENT}
</Inputs>

<Instructions Structure>
1. Present the provided Python file content to the assistant.
2. Break down the task into an extraction of class names and methods from the provided code.
3. Ensure that for each class, the assistant lists all its methods, and for each method:
   - Capture the method name.
   - Identify the method's input parameters.
   - Summarize the core process of the method in less than 50 words.
   - Specify the type of the output and describe its meaning.
4. Output the response in a structured format with clear divisions between classes and methods.
</Instructions Structure>

<Instructions>
You will be provided with the content of a Python file. Your task is to extract the class definitions and their methods, then rewrite them in a specific structured format.

Here are the steps to follow:

1. **Extract Classes**: Identify all class definitions within the code. 
2. **Extract Methods**: For each class, list all its methods. For each method, document the following:
   - **Method Name**: Write the name of the method.
   - **Inputs**: List the input parameters of the method.
   - **Main Process**: Summarize the core process of the method in fewer than 50 words.
   - **Output**: Identify the return type and provide a brief description of its meaning.

3. **Formatting**: Your output should be structured like this:"""

    @staticmethod
    def sumarize(code):
        input_prompt = Sumarizer.system_prompt.format(PYTHON_FILE_CONTENT=code)
        from openai import OpenAI

        client = OpenAI()

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": input_prompt}],
            temperature=0.0,
            max_tokens=2000,
            top_p=1,
        )
        return response.choices[0].message.content


def extract_functions_from_file(file_content):
    function_pattern = re.compile(r"^\s*def\s+\w+\s*\(.*\)\s*:")
    lines = file_content.splitlines()
    functions = []

    i = 0
    while i < len(lines):
        line = lines[i]
        match = function_pattern.match(line)

        if match:
            # Store the start of the function
            function_start = i

            # Determine the indentation level of the function definition
            indentation_level = len(line) - len(line.lstrip())

            # Now find where the function block ends
            j = i + 1
            while j < len(lines):
                next_line = lines[j]
                next_indentation_level = len(next_line) - len(next_line.lstrip())

                # If the next line is indented less or equally to the function, it means the block ended
                if (
                    next_line.strip() == ""
                    or next_indentation_level <= indentation_level
                ):
                    break
                j += 1

            # Store the function's start and end line numbers
            functions.append((function_start, j))

            # Move the index to the end of the function block
            i = j
        else:
            i += 1

    return functions


# Example usage
python_file_content = """
def foo(x):
    y = x + 1
    return y

def bar(a, b):
    result = a * b
    return result
"""

print(Sumarizer.sumarize(python_file_content))
