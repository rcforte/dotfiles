# Dynamo: How to Design a Key-value Store?

## Introduction

- Distributed key-value store designed for high availability and 
  partitioning.

- Designed to be imperfect but available. 

- Designed to be highly scalable, de-centralized, and eventually 
  consistent.

- Good for Primary-key only queries. High availability, high scalability, 
  eventually consistent.

- Provides get/set apis. It also includes a context object with user 
  metadata about the value. It uses consistent hashing to find out what server 
  to use.

## High Level Architecture

- Replicates data using consistents-hashing.

- Replicates data to a number of nodes, therefore it can deal with a node 
  failures.

- Uses the gossip protocol to find out if any node changes in the cluster.

## Data Partitioning

- Bucket hashing uses hash(key) % N to find the bucket slot in which to 
  and an entry. Consistent-hashing says only special buckets can take keys.
  This way, when a bucket is identified, the algo looks for the next special
  bucket that can take the key. This way, when a special bucket is removed
  only the items to the left of it need to be re-assigned. When a special 
  bucket is added, it will automatically start getting keys and decreasing 
  the load on the next special bucket.

  ***START REVIEW***

  The hash functions for special buckets may not distribute them evenly
  across the buckets. This means some special buckets may end up receiving
  more keys than others, causing an imbalance. We can solve this using 
  virtual special buckets. You can do this reusing the same special buckets,
  and applying other hash functions on them so that the same special bucket can 
  be assigned to different slots in your ring.

  *** END REVIEW ***

- Dynamo uses consistent-hashing. In order to avoid hotspots recalculating
  tokens (key ranges), Dynamo uses a scheme known as v-nodes, where each 
  physical node is mapped to multiple tokens. NOTE: possible implementation
  of this v-node idea is using multiple hash functions as described by the 
  video of the Indian guy.

## Replication

- Dynamo replicates data asynchronously on the background, and only for a few 
  nodes (the replication factor) in the instance. Each key is assigned a 
  coordinator node, which is the first node of the range. It is important to 
  note that some nodes may be down when the write is happening, which means 
  some instances may have a different version of the values, which is a 
  consistency problem. This will be solved with ***vector clocks***. If the 
  replication factor is N, then Dynamo will store N versions of the data in the 
  cluster.

- Preference list is the list of nodes that will maintain the replica of the 
  key-value written. It will be the first node in the range, followed by the 
  next N-1 nodes clockwise.

- *Sloppy quorum and handling of temporary failures:* A read/write is not 
  successful if it is not completed in all healthy nodes of the preference 
  list.

- *Hinted-handoff:* When Dynamo reads/writes, it needs a sloppy quorum. If
  some of the nodes of the quorum are down, Dynamo will find the next node
  clockwise that does not have the replica and will transfer it temporarily.

  The replica data will be on temporary storage and will have a hint in the
  metadata that it is replacing the original node. When the original node is
  back, the temporary node will transfer data+replica back to original node
  and delete it. This process is called hinted-handoff because Dynamo hands
  off the data/replica of a node to another one and writes a hint in the 
  metadata.

## Vector Clocks and Conflicting Data

- *What is clock skew?* Different computer clocks operate at different 
   frequencies. This means that different machines will be out of sync.
   NTP does not guarantee the syncup, we need special hardware for that.

- *What is a vector clock?* It is a pair[node,counter]. Because of hinted
   handoffs, replicas can have different values across the cluster. When
   that happens, we say the objects are on parallel branches. For example,
   server A handles write for key 1, the clocks records [A,1] and [A,1]
   is replicated to server B. The networks between A,B do down. Server B
   handles write for key 1, [B,1] is recorded. When the network comes back
   and clients read key 1, they will receive 2 objects: [[A,1], [B,1]] and
   decide how to solve the conflict.

- *Conflict-free replicated data types:* This is the case for idempotent
   functional types. A shopping cart is a great example of this model. You
   can add items or remove them (negative sum) and it does not matter the
   order, your data is always replicated consistently across the cluster.

- *Last-write-wins:* It is a conflict resolution policy in which the last
   write wins based on the timestamp. This can cause issues and may cause
   data loss.

## The life of Dynamo's put() & get() Operations

- Strategies for choosing the coordinator: (1) load balancer or (2)
  smart client. The second approach needs the client to know the ring so
   that the request goes directly to nodes in the preference list. 
   The second approach provides lower latency, but it is tightly coupled.

- Consistency protocol: Dynamo uses <N,R,W> = <3,2,2>. Less W makes 
  writes faster, reads slow, durability low. More W makes write slow, 
  read fast, more durable.

- Put process: (1) coordinator gets request, (2) updates vector clock, 
  (3) saves data locally, (4) replicates data to N-1 nodes in the 
  preference list, (5) marked successfull when receives W-1 
  confirmations.

- Get process: (1) coordinator gets the request (2) sends request to N-1
  nodes in the preference list, (3) receives replies from R-1 nodes,
  (4) deals with conflicts and sends all relevant information back to the
  client.

- Request handling through state machine: Each request to Dynamo creates 
  a workflow or state machine. The machine coordinates saving data, sending
  replicas, receiving responses from preference list nodes, and in the case
  of conflicts, it waits for the client to send the up-to-date information.
  This process is known as read repair.

## Anti-entropy Through Merkle Trees

- What are merkle trees? Binary search tree where the values are the hashes
   of children nodes.

- How is it used? MTs are created for different key ranges in the replica
   nodes. The roots of the MTs are then compared. If the values do not match
   there is a conflict, then the algo does a DFS to find exacly what data
   parts are causing the conflict. Once they are identified (efficiently)
   the conflict that can resolved. So the tree is used to spot data out of
   sync.

## Gossip Protocol

- What is gossip protocol? There is no centralized controller node, every
  minute each node exchanges information with another random node. Every
  minute each node exchanges information with another node about all the 
  servers it knows. There are seed nodes that are reference nodes, new nodes
  joining the cluster speak to the seed nodes to validate what they learned
  from other nodes.

## Dynamo Characteristics and Criticism

- Responsibilities of a Dynamo node: (1) handle get/put, handle 
  replication, or forward the request if not proper, (2) store data
  locally, (3) keep track of membership and detect failures and conflicts.

- Characteristics of Dynamo: highly available, decentralized, distributed,
  scalable, fault-tolerant, custom consistency, durable, eventually 
  consistent.

- Criticism on Dynamo: (1) every nodes knows the ring, which can make the
  system slow over time (2) leaky abstraction due to client handling of
  read consistency.

- Databases developed on the principles of Dynamo: Riak and Cassandra.

# Cassandra: How to Design a Wide-column NoSQL Database?

## Cassandra: Introdution

- Goal: Provide a distributed system that can store huge amounts of data,
  index rows by key, and uses structured data.

- Background: Developed at facebook, based on amazon Dynamo and Google 
  BigTable. Cassandra is a wide-column database. 

- What is Cassandra? Distributed, decentralized, scalable NoSQL database. It
  is a AP system. It can be tuned for replication and consistency. Higher
  levels of consistency come with performance penalty. Cassandra uses a 
  peer-to-peer protocol, every node is able to execute all database 
  operations.

- Cassandra use-cases: Cassandra is optimized for writes and high 
  throughput.

## High-level Architecture

- Cassandra common terms: The lowest level concept in cassandra is a column,
  columns have ids and values. Rows are collections of columns. Tables are
  collections of rows. Keyspaces are collections of tables. Clusters are 
  collections of keyspaces. Nodes are physical hosts running cassandra 
  instances. NoSQL refers to databases that do not support joins and there 
  are no foreign keys. It does not support columns in the where clause other
  than the primary key.

- High-level architecture

  1. Data partitioning: Cassandra uses consistent hashing just like Dynamo.
     It uses it for data **partitioning**.

  2. Cassandra Keys: primary_key = partition_key + clustering key. The 
     partition key is the key used for hashing the entry to the consistent
     hashing ring.

  3. Clustering Keys: Clustering key defines way data will be sorted in the 
     node.

  4. Partitioner: hashes the key and sends to the proper node in the ring.

  5. Coordinator Node: Node that receives a request from a client. If the 
     received key is not part of the range covered by the coordinator, it 
     will forward the request to the nodes responsible for that data range.

## Replication

1. Replication factor decides how many replicas the system has and 

2. Replication strategy decides which nodes will receive the replicas.

- *Simple replication strategy and network topology strategy:* The simple 
  strategy follows the same replication of Dynamo, i.e. it sends the 
  replicas to the next nodes clockwise. Network topology strategy allows 
  different replication in different networks.

## Cassandra Consistency Levels

- *Write Consistency Levels:* 

  1. 1/2/3 exact number of replica nodes, 

  2. Quorum: floor(RF/2+1), 

  3. All replica nodes, 

  4. local_quorum is quorum in the local datacenter, 

  5. each_quorum is quorum in each data center,

  6. any writes to only 1 replica.

- *Hinted-handoff:* similar to Dynamo, the coordinator writes a hint file in
  the local disk. The hint contains data + metadata. The gossiper let's the
  coordinator know the node has recovered and the coordinator sends the 
  replica data to the node.

- *Read Consistency levels:* Same as write, except if CL is each_quorum. The 
  Snitch tells the fastest replicas, when reading Cassandra asks data to 
  fastest replica and hash to second fastest replica. If any fails, read
  repair. The coordinator gets latest version of the data based on timestamp
  and starts read-repair sending latest version to all replicas. Cassandra 
  tries to read-repair 10% of the requests in the DC.

- *Snitch:* determines proximity and latency of replica nodes. Cassandra will
  try not to have more than 1 replica node per rack.

## Gossiper

- *How does Cassandra use gossip protocol?* Used for nodes to keep track of
  each other. Each gossip message has a version number.

  1. *Generation number:* gets incremented when the node restarts, nodes
     notified of restart when the number is incremented.

  2. *Seed nodes:* bootstrap the gossip process.

- *Node failure detection:* heartbeating is binary, depends on timeout and
  can signal failure when it is just slowness. A better approach is to use
  historical heartbeat information to make the threshold adaptative.

## *Anatomy of Cassandra's write operation:* 

1. node writes to commit log, 

2. node writes to MemTable, 

3. data flushed to SSTables, 

4. SST data gets compacted and merged.

- *Commit log:* append only file that is used for recovery (write-ahead)

- *MemTable:* In memory rbtree that keeps data sorted. When too big, gets 
  flushed.

- *SSTable:* Sorted String Table. Append only file that contains data. 

## Anatomy of Cassandra's read operation: 

- *Caching:* (1) Row cache keeps full data rows, (2) key cache keeps the map
   between key and offsets (3) chunk cache maintains uncompressed SSTable
   data.

- *Reading from MemTable:* MemTable is a red-black tree that keeps data 
  sorted in memory. 

- *Reading from SSTables:* If data is not found in memory, Cassandra needs to
   look it up on SSTable files. We can have many SSTable files, and reading
   each one requires I/O. In order to avoid I/O, Cassandra uses BloomFilters
   which return maybe if key possibly in the SSTables, or no if it is
   definitly not in the SSTables. This saves a lot of time. Bloomfilters are
   a bitvector that contains 1s on slots mapped to the result of multiple
   hashing operations on the key.

- *How are SSTables stored in the disk:* (1) data file containing the data
   sorted by partition key and clustering keys (2) partition index file
   containing the mapping between partition key and SSTable offsets.

- *Partition Index Summary:* Stored in memory, maps partition index to the 
   range of offsets.

- *Reading SSTable through key cache:* key cache contains mapping between 
   partition key and SSTable offsets. If they key is found, Cassandra jumps
   straight to the file offsets and retrieves the data.

## Compaction

- How it works: As Cassandra is flushing MemTables to disk, SSTables get 
  merged and consolidated into bigger SSTable files. This process is known
  as compaction.

- Strategies: (1) Size strategy ideao for fast writes, (2) level strategy
  ideal for read speed, (3) timeseries strategy good for timeseries data.

## Tombstones: 
   Tombstones are soft deletes. Records are market for deletion with a 
   Tombstone, it has an expiry date, and the nodes are physically deleted 
   during compaction. Any row with an expired tombstone will not be 
   propagated.

# Kafka

## Introduction

- Design a distributed messaging system that can transfer data between 
  entities.

- kafka is a distributed commit log (append only)

## Common terms

- *Broker:* server

- *Record:* message/row

- *Topic:* category/table

- *Producers:* Publish messages

- *Consumers:* Read/Consume messages

- Kafka is deployed as a cluster of nodes

- Kafka is statless and uses zookeeper to keep all information about cluster 
  nodes.

## Deep-Dive

- *Topic Partitions:* kafka topics can be broken down into partitions. 

  Partitions can be distributed to different brokers. Partitions keep 
  messages ordered by arriving order. Producers decide what partition they 
  will write to.  Messages are identified by topic, partition, and offset. 
  Offsets are message ids and unique in the partition.  Messages are 
  immutable, keys are ways of aggregating data into partitions.

  Kafka is dump broker, smart consumer. The consumer keeps an offset of where 
  to start receiving messages from. WRT replication, each partition has a 
  leader broker.

- *Leaders:* brokers responsible for all reads/writes of specific partition.

- *Follower:* backup of partition. Kafka stores the location of each leader
  in zookeeper.
  
- *In-sync-replicas(ISRs):* Are followers that have the latest version of the
  data. The leader is also an ISR. There is a minimum number of ISRs that 
  need to be updated before kafka marks a message as written and starts
  republishing it.

- *High-water mark:* it is the offset of a message that has been successfully
  replicated to all ISRs. This avoids non-repeatable reads.

## Consumer groups:

- groups of consumers. Messages are evenly distributed. No two consumers
  will receive the same message.

- relationship between partition and consumer is n-to-1 in the group

- if have more consumers than partitions, some consumers will be idle.

- if have less consumers than partitions, some consumers will have more 
  than one partition

## Kafka workflow

- Producer sends a message kafka

- Consumer connects to Kafka, Kafka returns the current offset of the 
  partition

- Consumer processes messages and acks, Kafka records the incremented offset 
  for that customer.

- Consumers can rewind the offset

## Controller Broker

- 1 broker is selected to perform admin tasks

- Split-brain: when a controller is too slow and presumed dead, the system
   starts a new controller, when the old one comes back online it is 
   considered a zombie controller.

- Generation clock: timestamp to signal there is a new controller. If zombie
   controller sends a message to brokers, it will have an old timestamp and
   brokers can ignore it.

## Kafka delivery semantics:

- Producer: (1) async means no ack, (2) ack from leader, (3) ack from leader
  + ISRs. (1) is faster and less durable, (3) is slowest and most durable.

- Consumer: (1) consumer commits before processing, (2) consumer commits 
  after processing, (3) consumer commits and processes at same time(this means
  we need transactional support).

- Consumer: (1) consumer commits before processing, (2) consumer commits 
  after processing, (3) consumer commits and processes at same time(this means
  we need transactional support).

## Kafka characteristics:

- Kafka only stores messages into disk.

- It does it sequentially, which is faster than random disk access.

- It uses OS tricks, such as read-ahead, write-behind, pagecache, zero-copy.

- Kafka retains records until runs out of space. It can be configured to
  use time, size, or compaction.

- Clients can have a byte quota in order to avoid monopoly of resources.

# GFS(Google File System)

## Introduction: 

Distributed file system optimized for large files. It optimizes large 
sequencial reads and writes, as well as small random reads.  It is designed 
for app-to-app communication.

## High-level architecture: 

- Chunks: file parts

- Chunk handle: id to each file part.

- Cluster: Master, Servers, Client.

- ChunkServer: stores chunks, replicates to 3 servers.

- Master: coordinates and stores metadata.

- Client: gets chunk location from master and reads from chunkservers.

## Single Master and Large Chunk

- Masters are not involved in read/writes. They tell clients what chunkserver
  to contact.

- Chunks are dynamically allocated and grow on demand.

- Large chunks may cause hotspots for small files.

## Metadata 

1. Master keeps dir hierarchy 

2. Master keeps map to chunks 

3. Master keeps track of replicas.

- all metadata is in memory for fast processing

- 1&2 are also stored on disk

## Operations Log

- 1&2 are stored in the ops log and send to replicas. Metadata changes need
  to be replicated to all replicas.

## Checkpointing

- Master state is periodically saved to disk in a b-tree and replicated

## Master Ops

- Manages metadata and locking

- Places replicas in different racks.

- Creates replicas and re-replicates in case disk space is running low/high

## Anatomy of a read op

- Client calculates the chunk index based on the filename and offset of the 
  file.

- Client asks the master for the location of chunk index.

- Master replies with list of chunkservers that contain the chunk.

- Client saves this in metadata and contacts the closest chunkserver.

- Client reads data from chunkserver.

## Anatomy of a write

- Chunk lease is used to serialize writes to the same chunk in different 
  servers.

- Sending: first client sends data to closest replica, this replica sends to 
  others

- Writing: once data is received, client sends to primary requesting write.  
  Primary writes in serial order and replicates.

# HDFS

## Hadoop Distributed File System: Introduction

- Distributed file system that can store huge files. Scalable, Reliable, and
  Highly Available.

- Built for unstructured data, variant of GFS, write-once/read-many.

- Better for batch processes handling huge data sets.

- Not good for low latency apps.

- Not good for lots of small files.

- No concurrent writers, append-only.

## HDFS Architecture

- Very similar to GFS.

- NameNode and DataNodes for metadata and file content respectively.

- Each block is identified by a 64-bit BlockId.

- When DataNode starts up, it sends a list of blocks it contains to the 
  NameNode.

- NameNode keeps a FsImage for metadata snapshot and a EditLog with all 
  operations executed since the last snapshot. This is used for disaster
  recovery.

## HDFS Deep Dive

- *Rack aware replication:* Nodes are connected via switches in racks, which
  connect to core switches with other racks.

- HDFS replication tries to minimize network distance (distance is measure
  in hops, where 1 hope represents one link in the topology.)

- HDFS tries to avoid putting too many replicas in one rack.

- HDFS implements strong consistency, so writes are declared successful only
  after replicas have been successfully written.

## HDFS Anatomy of a Read Operation

- Client sends read reques to NameNode and receives metadata, including the
  list of DataNodes for each one of the offsets.

- Client connects to the DataNode and starts reading the file via streaming.

- NameNode will select replicas based on the following criteria:
  1. same node if available;
  2. same rack if available;
  3. a different rack

- If blocs are on the same node as the client, HDFS will try to bypass the
  TCP connection and read the file content directly. This process is called 
  ***short circuit read***

## HDFS Anatomy of a Write Operation

- Client sends request to NameNode and gets an ok to write the file.

- Client starts writing the file a local buffer until the block is complete.

- Client starts a DataStream components that will ask the NameNode to allocate
  a new DataNode + replicas for this block.

- DataStream starts writing data to the closest replica and the replica starts
  writing it to the other replicas, so that the writing and replication happen
  as part of the same process from a client perspective.

- DataStream finishes writing the content and asks the NameNode to commit the
  file creation. At this point the file becomes available for reads.

## HDFS Data Integrity & Caching

- HDFS uses checksum to make sure corrupted data is not received by clients.

- BlockScanners run on the background and verify blocks match their checksums.

- Clients can tell the NameNode to cache blocks in memory. When blocks are 
  cached, they are loaded into off-heap memory and zero-copy can be used to
  transfer them to clients.

## HDFS Fault Tolerance

- HDFS NameNode keeps track of DataNodes using heartbeats.

- NameNode periodically checks the system to find under-replicated blocks and
  perform a cluster rebalance to replicate blocks that do not have enough 
  replicas.

- When a NameNode fails, it can be recovered by the FsImage and EditLog files.

- When a NameNode disk fails, the file should be recovered from a NFS.

- ... Or HDFS can mantain a Secondary NameNode. This node only merges the 
  FsImage and EditLog of the primary NameNode. It can still lag the state, so
  even if we are using a secondary replica, we should still copy the files to
  a Network File System (NFS)

## HDFS High Availability

- HDFS NameNode takes a long time to start in case of a failure.

- HDFS 2.0 adds HA, which allows active/passive NameNodes.

- EditLog is replicated using Quorum Journal Manager (QJM)

- Zookeeper is says who is the primary NameNode. It keeps client processes in
  each NameNode for monitoring and coordination with the central zookeeper 
  server.

- Graceful failover are used for maintenance. Ungraceful is when the node fails.

- If the node is slow, we end up in a split brain scenario.

- HDFS uses fencing to deal with split-brain or zoombie NameNodes. It blocks
  the node from accessing the cluster either via the NFS or physical powring
  off the box.

## HDFS Characteristics

- Security is similar to POSIX and Linux

- NameNode keeps metadata in memory, which means it needs a lot of memory for
  big clusters. HDFS 2.x introduced federated NameNodes, which means there will
  be one different NameNode responsible for a predefined root "folder". This
  means the client will need a mapping between root folders and NameNodes. This
  also means different NameNodes can create the same BlockIDs, which means 
  BlockIDs will be composed by (BlockPoolID, BlockID). The DataNodes will be 
  shared among federated NameNodes.

- Replication creates resource overhead (3 replicas, 200% of storage overhead)
  Erasure coding compresses and encodes parts of blocks and distributes to other
  nodes saving space.



































