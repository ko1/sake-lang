import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;

/** Entry point: reads a SQL script from standard input, runs it, prints results to standard output. */
public final class Main {
    private Main() {}

    public static void main(String[] args) throws IOException {
        String script = new String(System.in.readAllBytes(), StandardCharsets.UTF_8);
        StringBuilder out = new StringBuilder();
        Executor executor = new Executor(out);
        for (String statement : Script.split(script)) executor.runStatement(statement);
        PrintStream stdout = new PrintStream(System.out, false, StandardCharsets.UTF_8);
        stdout.print(out);
        stdout.flush();
    }
}
