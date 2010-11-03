/**
 * 
 */
package BAMStats;

/**
 * @author niravs (Nirav Shah)
 * Enum to represent whether to consider read 1, read 2 or fragments
 */
public enum ReadType
{
	Read1,   // Read 1 of paired read
	Read2,   // Read 2 of paired read
	Fragment // Fragments - i.e. unpaired reads
}
