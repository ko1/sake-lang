import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import sqlengine.exec.Database;
import sqlengine.exec.Executor;
import sqlengine.parse.Ast;
import sqlengine.parse.Lexer;
import sqlengine.parse.Parser;
import sqlengine.parse.SqlError;

/** Reads a SQL script from standard input and runs it; see SPEC.md. */
public final class Main {
    public static void main(String[] args) throws IOException {
        String script = new String(System.in.readAllBytes(), StandardCharsets.UTF_8);
        PrintStream out = new PrintStream(new java.io.FileOutputStream(java.io.FileDescriptor.out), false,
            StandardCharsets.UTF_8);
        Executor exec = new Executor(new Database());
        List<Object> statements = Parser.parseScript(Lexer.tokenize(script));
        for (Object st : statements) {
            StringBuilder buf = new StringBuilder();
            try {
                if (st instanceof SqlError e) throw e;
                exec.execute((Ast.Stmt) st, buf);
            } catch (SqlError e) {
                buf.setLength(0);
                buf.append("Error: ").append(e.getMessage()).append('\n');
            } catch (RuntimeException e) {
                buf.setLength(0);
                buf.append("Error: internal error: ").append(e).append('\n');
            }
            out.print(buf);
        }
        out.flush();
    }
}
