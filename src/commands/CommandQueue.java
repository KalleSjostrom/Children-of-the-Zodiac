package commands;

import java.util.Stack;

import bodies.Bodies;

public class CommandQueue {
	
	private Stack<Command> pq;
	
	public CommandQueue() {
		pq = new Stack<Command>();
	}
	
	public void enqueue(Command command) {
		pq.push(command);
	}

	public void run(Bodies bodies, float elapsedTime) {
		Command c;
		while(!pq.isEmpty()) {
			c = pq.pop();
			c.execute(bodies, elapsedTime);

		}
	}
}
